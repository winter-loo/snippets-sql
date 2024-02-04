--
-- PLPGSQL_STMT_ASSIGN
--
CREATE OR REPLACE FUNCTION example_assign()
RETURNS VOID AS
$$
DECLARE
  a INTEGER := 10;
BEGIN
  -- Your statements here
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_PERFORM
--
CREATE OR REPLACE FUNCTION example_perform()
RETURNS VOID AS
$$
BEGIN
  PERFORM some_function();
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_CALL
--
CREATE OR REPLACE FUNCTION example_call()
RETURNS VOID AS
$$
BEGIN
  CALL some_procedure();
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_IF
--
CREATE OR REPLACE FUNCTION example_if()
RETURNS VOID AS
$$
DECLARE
  a INTEGER := 10;
BEGIN
  IF a > 5 THEN
    -- Your statements here
  END IF;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_CASE
--
CREATE OR REPLACE FUNCTION example_case()
RETURNS VOID AS
$$
DECLARE
  a INTEGER := 10;
BEGIN
  CASE
    WHEN a > 5 THEN
      -- Your statements here
  END CASE;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_LOOP
--
CREATE OR REPLACE FUNCTION example_loop()
RETURNS VOID AS
$$
DECLARE
  a INTEGER := 10;
BEGIN
  LOOP
    -- Your statements here
    EXIT WHEN a > 5;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_WHILE
--
CREATE OR REPLACE FUNCTION example_while()
RETURNS VOID AS
$$
DECLARE
  a INTEGER := 10;
BEGIN
  WHILE a > 5 LOOP
    -- Your statements here
  END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_FORI
--
CREATE OR REPLACE FUNCTION example_fori()
RETURNS VOID AS
$$
DECLARE
  a INTEGER;
BEGIN
  FOR a IN 1..10 LOOP
    -- Your statements here
  END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_FORC
--
CREATE OR REPLACE FUNCTION example_forc()
RETURNS VOID AS
$$
DECLARE
  x text;
BEGIN
  FOR x IN SELECT name FROM some_table LOOP
    RAISE NOTICE 'Name: %', x;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_FORS
--
CREATE OR REPLACE FUNCTION example_fors()
RETURNS VOID AS
$$
DECLARE
  a RECORD;
BEGIN
  FOR a IN SELECT * FROM some_table LOOP
    RAISE NOTICE 'id: %, name: %', a.id, a.name;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_FOREACH_A
--
CREATE OR REPLACE FUNCTION example_foreach_a()
RETURNS VOID AS
$$
DECLARE
  a INTEGER[];
  first_name char(10);
BEGIN
  a := ARRAY[1, 2, 3];
  FOREACH i IN ARRAY a LOOP
    SELECT name INTO first_name FROM some_table WHERE id = i;
    RAISE NOTICE 'First Name: %', first_name;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_RETURN_NEXT
--
CREATE OR REPLACE FUNCTION example_return_next()
RETURNS SETOF orders AS
$$
DECLARE
  r orders%ROWTYPE;
BEGIN
  FOR r IN SELECT * FROM orders where id > 0 LOOP
    RETURN NEXT r;
  END LOOP;
  RETURN;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_RETURN_QUERY
--
CREATE OR REPLACE FUNCTION example_return_query()
RETURNS SETOF orders AS
$$
BEGIN
  RETURN QUERY SELECT * FROM orders where id > 0;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_EXECSQL
--
CREATE OR REPLACE FUNCTION example_execsql()
RETURNS VOID AS
$$
BEGIN
  EXECUTE 'SELECT * FROM orders';
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_DYNEXECUTE
--
CREATE OR REPLACE FUNCTION example_dynexecute()
RETURNS VOID AS
$$
DECLARE
  a INTEGER := 10;
  b INTEGER;
BEGIN
  EXECUTE 'SELECT $1 + $2' INTO b USING a, 5;
END;

--
-- PLPGSQL_STMT_OPEN
--
CREATE OR REPLACE FUNCTION example_open()
RETURNS VOID AS
$$
DECLARE
  r RECORD;
  c CURSOR FOR SELECT * FROM orders;
BEGIN
  OPEN c;
  FETCH c INTO r;
  CLOSE c;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_DYNFORS
--
CREATE OR REPLACE FUNCTION example_dynfors()
RETURNS VOID AS
$$
DECLARE
  r RECORD;
BEGIN
  FOR r IN EXECUTE 'SELECT * FROM orders' LOOP
    -- Your statements here
  END LOOP;
END;
$$
LANGUAGE plpgsql;
