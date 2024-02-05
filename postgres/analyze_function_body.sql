--
-- PLPGSQL_STMT_ASSIGN
--
CREATE OR REPLACE FUNCTION demo_assign()
RETURNS VOID AS
$$
DECLARE
  a INTEGER := 10;
BEGIN
  a := max(10, b);
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_PERFORM
--
CREATE OR REPLACE FUNCTION demo_perform()
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
CREATE OR REPLACE FUNCTION demo_call()
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
CREATE OR REPLACE FUNCTION demo_if(a INT)
RETURNS INT AS
$$
DECLARE
  b INT;
BEGIN
  IF a > 5 and a < 10 THEN
    SELECT total INTO b FROM orders WHERE id = a; 
  ELSIF a < 5 THEN
    SELECT total INTO b FROM orders WHERE id = a; 
  ELSE
    SELECT total INTO b FROM orders WHERE id = a;
  END IF;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_CASE
--
CREATE OR REPLACE FUNCTION demo_case()
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
CREATE OR REPLACE FUNCTION demo_loop()
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
CREATE OR REPLACE FUNCTION demo_while()
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
CREATE OR REPLACE FUNCTION demo_fori()
RETURNS VOID AS
$$
DECLARE
  a INTEGER;
  b INTEGER;
BEGIN
  FOR a IN 1..10 LOOP
    select total into b from orders where id = a;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

-- procedure
CREATE OR REPLACE PROCEDURE pr_foo()
AS
$$
DECLARE
  var_start int := 0;
  var_end   int := 1;
  var_sum   int := 0;
  totalsum  int := 0;
BEGIN
   FOR i in var_start..var_end LOOP
     raise notice 'iteration %', i;
     select total into var_sum from orders where id = i;
     totalsum := totalsum + var_sum;
   END LOOP;
   raise notice 'totalsum %', totalsum;
END;
$$
LANGUAGE plpgsql;


--
-- PLPGSQL_STMT_FORC
--
CREATE OR REPLACE FUNCTION demo_forc()
RETURNS VOID AS
$$
DECLARE
  rec RECORD;
  my_cursor CURSOR FOR SELECT id, name FROM my_table;
BEGIN
  FOR rec IN my_cursor LOOP
    RAISE NOTICE 'ID: %, Name: %', rec.id, rec.name;
  END LOOP;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_FORS
--
CREATE OR REPLACE FUNCTION demo_fors()
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
CREATE OR REPLACE FUNCTION demo_foreach_a()
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
CREATE OR REPLACE FUNCTION demo_return_next()
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
CREATE OR REPLACE FUNCTION demo_return_query()
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
CREATE OR REPLACE FUNCTION demo_execsql()
RETURNS VOID AS
$$
DECLARE
  var_id INTEGER;
  var_total INTEGER;
BEGIN
  SELECT id, total into var_id, var_total FROM orders;
  raise notice 'ID: %, Total: %', var_id, var_total;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION demo_execsql2(
  p_id INTEGER,
  p_total INTEGER
)
RETURNS VARCHAR AS
$$
DECLARE
  var_id INTEGER;
BEGIN
  INSERT INTO orders (id, total) VALUES (p_id, p_total) RETURNING id INTO var_id2;
  RETURN 'ID: ' || var_id;
END;
$$
LANGUAGE plpgsql;

--
-- PLPGSQL_STMT_DYNEXECUTE
--
CREATE OR REPLACE FUNCTION demo_dynexecute()
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
CREATE OR REPLACE FUNCTION demo_open()
RETURNS VOID AS
$$
DECLARE
  r RECORD;
  c CURSOR FOR SELECT id, total FROM orders;
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
CREATE OR REPLACE FUNCTION demo_dynfors()
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
