CREATE TABLE IF NOT EXISTS Employee (
  id INT UNSIGNED AUTO_INCREMENT NOT NULL,
  first_name VARCHAR(250),
  last_name VARCHAR(250),
  email VARCHAR(250),
  username VARCHAR(250) NOT NULL,
  password VARCHAR(100) NOT NULL,
  regdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_employee_username (username)
);