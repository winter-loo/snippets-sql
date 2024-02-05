CREATE OR REPLACE FUNCTION insert_employee(
  p_employee_id INT,
  p_employee_name CHAR,
  p_salary INT
)
RETURN VARCHAR IS
  v_employee_id INT;
BEGIN
  INSERT INTO employees (employee_id, employee_name, salary)
  VALUES (p_employee_id, p_employee_name, p_salary)
  RETURNING employee_id INTO v_employee_id;

  RETURN 'Employee inserted with ID: ' || v_employee_id;
END insert_employee;
/

CREATE TABLE employees (
  employee_id INT PRIMARY KEY,
  employee_name CHAR(50),
  salary INT
);

DECLARE
  result VARCHAR(100);
BEGIN
  result := insert_employee(101, 'John Doe', 50000);
  DBMS_OUTPUT.PUT_LINE(result);
END;
/
