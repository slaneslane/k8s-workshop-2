import os
import socket
import time
import threading
import logging
from datetime import datetime, timezone

import psycopg
from flask import Flask, jsonify, request

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://workshop:workshop@postgres:5432/workshop")
LOG_FILE = os.getenv("LOG_FILE", "/data/events.log")
LOG_INTERVAL_SECONDS = int(os.getenv("LOG_INTERVAL_SECONDS", "15"))
CRASH_ON_START = os.getenv("CRASH_ON_START", "false").lower() == "true"
REQUIRE_DB_FOR_READY = os.getenv("REQUIRE_DB_FOR_READY", "true").lower() == "true"

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("workshop-app")

if CRASH_ON_START:
    raise RuntimeError("CRASH_ON_START=true: intentional training failure")


def now():
    return datetime.now(timezone.utc).isoformat()


def db_connection():
    return psycopg.connect(DATABASE_URL, connect_timeout=3)


def write_event(message: str):
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    line = f"{now()} host={socket.gethostname()} {message}\n"
    log.info(line.strip())
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line)


def background_logger():
    while True:
        try:
            write_event("periodic application event")
        except Exception as exc:
            log.warning("cannot write file log: %s", exc)
        time.sleep(LOG_INTERVAL_SECONDS)


threading.Thread(target=background_logger, daemon=True).start()


@app.get("/healthz")
def healthz():
    return jsonify(status="ok", version=APP_VERSION, host=socket.gethostname())


@app.get("/readyz")
def readyz():
    if not REQUIRE_DB_FOR_READY:
        return jsonify(status="ready", db_check="disabled")
    try:
        with db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("select 1")
                cur.fetchone()
        return jsonify(status="ready", database="ok")
    except Exception as exc:
        return jsonify(status="not-ready", database="failed", error=str(exc)), 503


@app.get("/version")
def version():
    return jsonify(version=APP_VERSION, host=socket.gethostname(), log_file=LOG_FILE)


@app.get("/items")
def list_items():
    with db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("select id, name, created_at from items order by id")
            rows = cur.fetchall()
    return jsonify(items=[{"id": r[0], "name": r[1], "created_at": r[2].isoformat()} for r in rows])


@app.post("/items")
def create_item():
    data = request.get_json(silent=True) or {}
    name = data.get("name", f"item-{int(time.time())}")
    with db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("insert into items(name) values(%s) returning id, name, created_at", (name,))
            row = cur.fetchone()
        conn.commit()
    write_event(f"created item id={row[0]} name={row[1]}")
    return jsonify(id=row[0], name=row[1], created_at=row[2].isoformat()), 201


@app.get("/file-log")
def file_log():
    if not os.path.exists(LOG_FILE):
        return jsonify(log_file=LOG_FILE, lines=[])
    with open(LOG_FILE, encoding="utf-8") as f:
        lines = f.readlines()[-20:]
    return jsonify(log_file=LOG_FILE, lines=[x.rstrip() for x in lines])


@app.get("/stress/cpu")
def stress_cpu():
    seconds = int(request.args.get("seconds", "10"))
    end = time.time() + seconds
    n = 0
    while time.time() < end:
        n += 1
    return jsonify(status="done", iterations=n, seconds=seconds)


@app.get("/stress/memory")
def stress_memory():
    mib = int(request.args.get("mib", "256"))
    chunks = []
    for _ in range(mib):
        chunks.append(bytearray(1024 * 1024))
    time.sleep(5)
    return jsonify(status="allocated", mib=mib)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
