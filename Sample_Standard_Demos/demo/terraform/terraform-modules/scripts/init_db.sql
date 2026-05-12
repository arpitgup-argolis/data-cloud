-- Sample SQL Initialization Script
CREATE TABLE IF NOT EXISTS demo_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO demo_table (name) VALUES ('Initial Data Item');
