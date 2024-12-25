--
-- PL/SQL Name Resolution
-- https://docs.oracle.com/en/database/oracle/oracle-database/19/lnpls/plsql-name-resolution.html#GUID-848E544F-7C7A-41F6-BFDC-BBEC58DC6F24
-- 
create schema s1;
create schema s2;

create table s1.t(a int);
insert into s1.t values (1);

create table s2.t(a int);
insert into s2.t values (2);

create table t(a int);
insert into t values (3);

create or replace function s1.fn() returns int
as
$$
declare
  v_a int := 0;
begin
  set search_path to "s1";
  select a into v_a from t limit 1;
  reset search_path;
  return v_a;
end;
$$ language plpgsql;

create or replace function s2.fn() returns int
as
$$
declare
  v_a int := 0;
begin
  set search_path to "s2";
  select a into v_a from t limit 1;
  reset search_path;
  return v_a;
end;
$$ language plpgsql;

--= 1
select s1.fn();

--= 2
select s2.fn();
