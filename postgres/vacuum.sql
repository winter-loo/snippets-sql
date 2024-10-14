CREATE OR REPLACE FUNCTION heap_page(relname text, pageno integer)
RETURNS TABLE(
ctid tid, state text,
xmin text, xmax text,
hhu text, hot text, t_ctid tid
) AS $$
SELECT (pageno,lp)::text::tid AS ctid,
CASE lp_flags
WHEN 0 THEN 'unused'
WHEN 1 THEN 'normal'
WHEN 2 THEN 'redirect to '||lp_off
WHEN 3 THEN 'dead'
END AS state,
t_xmin || CASE
WHEN (t_infomask & 256) > 0 THEN ' c' /* xmin committed */
WHEN (t_infomask & 512) > 0 THEN ' a' /* xmin invalid/aborted */
ELSE ''
END AS xmin,
t_xmax || CASE
WHEN (t_infomask & 1024) > 0 THEN ' c' /* xmax committed */
WHEN (t_infomask & 2048) > 0 THEN ' a' /* xmax invalid/aborted */
ELSE ''
END || CASE
WHEN (t_infomask & 4096) > 0 THEN ' m' /* multixact id */
ELSE ''
END AS xmax,
CASE WHEN (t_infomask2 & 16384) > 0 THEN 't' END AS hhu,
CASE WHEN (t_infomask2 & 32768) > 0 THEN 't' END AS hot,
t_ctid /* current TID of this or newer row version */
FROM heap_page_items(get_raw_page(relname,pageno))
ORDER BY lp;
$$ LANGUAGE sql;


CREATE FUNCTION index_page(relname text, pageno integer)
RETURNS TABLE(itemoffset smallint, htid tid, dead boolean)
AS $$
SELECT itemoffset,
htid,
dead -- starting from v.13
FROM bt_page_items(relname,pageno);
$$ LANGUAGE sql;

--
-- page pruning
--{
CREATE TABLE hot(id integer, s char(2000)) WITH (fillfactor = 75, autovacuum_enabled = off);
CREATE INDEX hot_id ON hot(id);
CREATE INDEX hot_s ON hot(s);

INSERT INTO hot VALUES (1, 'A');
UPDATE hot SET s = 'B';
UPDATE hot SET s = 'C';
UPDATE hot SET s = 'D';

SELECT * FROM heap_page('hot',0);

-- upper - lower less than 2004 bytes
SELECT lower, upper, pagesize FROM page_header(get_raw_page('hot',0));

-- page pruning occurred
select * from hot;

-- dead tuple.
-- Why 'dead' instead of 'unused'? 
-- As there are indicies referencing them.
SELECT * FROM heap_page('hot',0);

SELECT * FROM index_page('hot_s',1);

SELECT * FROM index_page('hot_id',1);

-- index scan
EXPLAIN (analyze, costs off, timing off, summary off)
SELECT * FROM hot WHERE id = 1;

-- change to dead
SELECT * FROM index_page('hot_id',1);
--}

--
-- page pruning for HOT Updates
--{
DROP INDEX hot_s;
TRUNCATE TABLE hot;

INSERT INTO hot VALUES (1, 'A');
UPDATE hot SET s = 'B';

-- one Heap Hot Updated tuple and one Heap Only Tuple
SELECT * FROM heap_page('hot',0);

UPDATE hot SET s = 'C';
UPDATE hot SET s = 'D';
SELECT * FROM heap_page('hot',0);

-- the index still contains only one reference
SELECT * FROM index_page('hot_id',1);

-- trigger page pruning
UPDATE hot SET s = 'E';

SELECT * FROM heap_page('hot',0);

UPDATE hot SET s = 'F';
UPDATE hot SET s = 'G';

-- trigger page pruning
UPDATE hot SET s = 'H';

SELECT * FROM heap_page('hot',0);
--}

--
-- basic vacuum
--{
CREATE TABLE vac(
  id integer,
  s char(100)
) WITH (autovacuum_enabled = off);

CREATE INDEX vac_s ON vac(s);

INSERT INTO vac(id,s) VALUES (1,'A');

UPDATE vac SET s = 'B';

UPDATE vac SET s = 'C';

SELECT * FROM heap_page('vac',0);

SELECT * FROM index_page('vac_s',1);

VACUUM vac;

SELECT * FROM heap_page('vac',0);

SELECT * FROM index_page('vac_s',1);

CREATE EXTENSION pg_visibility; -- lt_visibility

SELECT all_visible FROM pg_visibility_map('vac',0);

SELECT flags & 4 > 0 AS all_visible
FROM page_header(get_raw_page('vac',0));
--}

--
-- freeze
--{
-- fillfactor 取最小值 10, 这样每一页就只能存 2 个元组
CREATE TABLE tfreeze(
  id integer,
  s char(300)
) WITH (fillfactor = 10, autovacuum_enabled = off);

CREATE FUNCTION heap_page(
  relname text, pageno_from integer, pageno_to integer
)
RETURNS TABLE(
  ctid tid, state text,
  xmin text, xmin_age integer, xmax text
) AS $$
SELECT (pageno,lp)::text::tid AS ctid,
CASE lp_flags
WHEN 0 THEN 'unused'
WHEN 1 THEN 'normal'
WHEN 2 THEN 'redirect to '||lp_off
WHEN 3 THEN 'dead'
END AS state,
t_xmin || CASE
WHEN (t_infomask & 256+512) = 256+512 THEN ' f' /* HEAP_XMIN_FROZEN */
WHEN (t_infomask & 256) > 0 THEN ' c'
WHEN (t_infomask & 512) > 0 THEN ' a'
ELSE ''
END AS xmin,
age(t_xmin) AS xmin_age,
t_xmax || CASE
WHEN (t_infomask & 1024) > 0 THEN ' c'
WHEN (t_infomask & 2048) > 0 THEN ' a'
ELSE ''
END AS xmax
FROM generate_series(pageno_from, pageno_to) p(pageno),
heap_page_items(get_raw_page(relname, pageno))
ORDER BY pageno, lp;
$$ LANGUAGE sql;

CREATE EXTENSION IF NOT EXISTS pg_visibility; -- lt_visibility
INSERT INTO tfreeze(id, s) SELECT id, 'FOO'||id FROM generate_series(1,100) id;

-- before vacuum, all_visible and all_frozen are both false
SELECT *
FROM generate_series(0,1) g(blkno),
pg_visibility_map('tfreeze', g.blkno)
ORDER BY g.blkno;

VACUUM tfreeze;

-- after vacuum, all_visible is true, all_frozen is false
SELECT *
FROM generate_series(0,1) g(blkno),
pg_visibility_map('tfreeze', g.blkno)
ORDER BY g.blkno;

-- all xmin_age equals 1
SELECT * FROM heap_page('tfreeze',0,1);

--}


--
-- minimal freezing age
--{
ALTER SYSTEM SET vacuum_freeze_min_age = 1;
select pg_reload_conf();

UPDATE tfreeze SET s = 'BAR' WHERE id = 1;

SELECT * FROM heap_page('tfreeze',0,1);

-- page 0 is not all_visible
SELECT * FROM generate_series(0,1) g(blkno),
  pg_visibility_map('tfreeze',g.blkno)

VACUUM tfreeze;

SELECT * FROM heap_page('tfreeze',0,1);

SELECT * FROM generate_series(0,1) g(blkno),
  pg_visibility_map('tfreeze',g.blkno)
ORDER BY g.blkno;
--}

--
-- age for aggressive freezing
--{
SELECT relfrozenxid, age(relfrozenxid)
FROM pg_class
WHERE relname = 'tfreeze';

ALTER SYSTEM SET vacuum_freeze_table_age = 4;
select pg_reload_conf();

VACUUM VERBOSE tfreeze;

SELECT relfrozenxid, age(relfrozenxid)
FROM pg_class
WHERE relname = 'tfreeze';

SELECT * FROM heap_page('tfreeze',0,1);

SELECT * FROM generate_series(0,1) g(blkno),
pg_visibility_map('tfreeze',g.blkno)
ORDER BY g.blkno;
--}

--
-- vacuum full
--{
TRUNCATE vac;

INSERT INTO vac(id,s)
SELECT id, id::text FROM generate_series(1,500000) id;

CREATE EXTENSION pgstattuple;
-- query data density
SELECT * FROM pgstattuple('vac') \gx
SELECT * FROM pgstatindex('vac_s') \gx

SELECT pg_size_pretty(pg_table_size('vac')) AS table_size,
  pg_size_pretty(pg_indexes_size('vac')) AS index_size;

DELETE FROM vac WHERE id % 10 != 0;

VACUUM vac;

-- table_size and index_size not changed
SELECT pg_size_pretty(pg_table_size('vac')) AS table_size,
  pg_size_pretty(pg_indexes_size('vac')) AS index_size;

SELECT vac.tuple_percent, vac_s.avg_leaf_density
FROM pgstattuple('vac') vac, pgstatindex('vac_s') vac_s;

SELECT pg_relation_filepath('vac') AS vac_filepath,
  pg_relation_filepath('vac_s') AS vac_s_filepath \gx

VACUUM FULL vac;

SELECT pg_relation_filepath('vac') AS vac_filepath,
  pg_relation_filepath('vac_s') AS vac_s_filepath \gx

SELECT pg_size_pretty(pg_table_size('vac')) AS table_size,
  pg_size_pretty(pg_indexes_size('vac')) AS index_size;

SELECT vac.tuple_percent, vac_s.avg_leaf_density
FROM pgstattuple('vac') vac, pgstatindex('vac_s') vac_s;


SELECT * FROM heap_page('vac',0,0) LIMIT 5;

SELECT * FROM pg_visibility_map('vac',0);

SELECT flags & 4 > 0 all_visible
FROM page_header(get_raw_page('vac',0));

VACUUM vac;

SELECT * FROM pg_visibility_map('vac',0);

SELECT flags & 4 > 0 all_visible
FROM page_header(get_raw_page('vac',0));
--}

--
-- multixact id
--{
create table tmxid(a int, b int);
insert into tmxid values (1, 1);

--! txn 1
begin;
select txid_current();
select * from tmxid for share;

--! txn 2
-- NOTE xmax
begin;
select xmin, xmax, * from tmxid;

--! txn 3
begin;
select txid_current();
select * from tmxid for share;

--! txn 2
-- NOTE xmax: reocrding multixact id
select xmin, xmax, * from tmxid;

--! txn 1
commit;

--! txn 3
commit;

--! txn 2
-- NOTE xmax keeps multixact id forever
select xmin, xmax, * from tmxid;

vacuum tmxid;

--! txn 2
-- NOTE xmax is now 0
select xmin, xmax, * from tmxid;
--}
