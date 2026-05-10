CREATE TABLE tasks (
                       id SERIAL PRIMARY KEY,
                       title VARCHAR(255),
                       status VARCHAR(50),
                       due_date DATE
);