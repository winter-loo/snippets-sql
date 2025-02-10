--
-- Returns a random text with at least length `length(gen_random_uuid())`
-- and with length equal to or slightly greater than `len`
--
create or replace function long_random_text(len int default 2048)
returns text
as $$
with recursive
    long_random_text(i, t) as (
        select 0, gen_random_uuid()::text
        union all
        select i + 1, t || gen_random_uuid()::text
        from long_random_text
        where i < ceil(len::float / length(gen_random_uuid()::text))
    )
select t
from long_random_text
where i = ceil(len::float / length(gen_random_uuid()::text)) - 1
$$
language sql
;

create extension pageinspect;
create or replace function heap_page(relname text, pageno integer)
returns table(ctid tid, state text, xmin text, xmax text)
as $$
SELECT (pageno,lp)::text::tid AS ctid,
CASE lp_flags
WHEN 0 THEN 'unused'
WHEN 1 THEN 'normal'
WHEN 2 THEN 'redirect to '||lp_off
WHEN 3 THEN 'dead'
END AS state,
t_xmin || CASE
WHEN (t_infomask & 256) > 0 THEN ' c'
WHEN (t_infomask & 512) > 0 THEN ' a'
ELSE ''
END AS xmin,
t_xmax || CASE
WHEN (t_infomask & 1024) > 0 THEN ' c'
WHEN (t_infomask & 2048) > 0 THEN ' a'
ELSE ''
END AS xmax
FROM heap_page_items(get_raw_page(relname,pageno))
ORDER BY lp;
$$
language sql
;


create extension pageinspect;
create or replace function index_page(relname text, pageno integer)
returns table(itemoffset smallint, htid tid)
as $$
SELECT itemoffset,
  htid -- ctid before v.13
  FROM bt_page_items(relname,pageno);
$$
language sql
;

