create table if not exists items (
  id serial primary key,
  name text not null,
  created_at timestamptz not null default now()
);

insert into items(name)
select 'first workshop item'
where not exists (select 1 from items where name = 'first workshop item');
