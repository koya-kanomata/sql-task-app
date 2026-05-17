CREATE USER taskuser WITH PASSWORD 'taskpass';
CREATE DATABASE sqltaskdb OWNER taskuser;
GRANT ALL PRIVILEGES ON DATABASE sqltaskdb TO taskuser;
