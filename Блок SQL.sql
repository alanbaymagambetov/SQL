/*
CREATE DATABASE final_project;

CREATE TABLE Customers
(Id_client INT,
Total_amount INT,
Gender VARCHAR(5) NULL,
Age INT NULL,
Count_city INT,
Response_communcation INT,
Communication_3month INT,
Tenure INT
);

ALTER TABLE Customers MODIFY AGE INT NULL;
UPDATE Customers SET Gender = NULL WHERE Gender = '';
UPDATE Customers SET AGE = NULL WHERE AGE = '';
SELECT * FROM Customers;

CREATE TABLE Transactions 
(date_new DATE,
Id_check INT,
ID_client INT,
Count_products DECIMAL (10,3),
Sum_payment DECIMAL (10,2)
); 

ALTER TABLE Transactions DISABLE KEYS;
SET foreign_key_checks = 0;
ALTER TABLE Transactions ENGINE=MyISAM;
SET SQL_LOG_BIN=0;

LOAD DATA INFILE 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\TRANSACTIONS.csv'
INTO TABLE Transactions
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;
SHOW VARIABLES LIKE 'secure_file_priv';
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

SELECT * FROM Transactions;
SELECT COUNT(*) FROM Transactions; 

ALTER TABLE Transactions ENABLE KEYS;
SET foreign_key_checks = 1;
ALTER TABLE Transactions ENGINE=InnoDB;
SET SQL_LOG_BIN=1;
*/

#1
SELECT t.ID_client, AVG(t.Sum_payment) as avg_check, AVG(c.Total_amount) as avg_month, COUNT(t.ID_client) as count_client, c.Tenure
FROM Transactions t 
JOIN Customers c ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY t.ID_client, c.Tenure
HAVING c.Tenure = 12;

#2
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, 
AVG(Sum_payment) AS avg_check_per_month,
COUNT(ID_check) / COUNT(DISTINCT ID_client) AS avg_operations_per_month,
COUNT(DISTINCT ID_client) AS avg_clients_per_month,
SUM(Sum_payment) / (SELECT SUM(Sum_payment) FROM Transactions WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01') * 100 AS monthly_operations_share,
COUNT(ID_check) / (SELECT COUNT(ID_check) FROM Transactions WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01') * 100 AS operations_share
FROM Transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY DATE_FORMAT(date_new, '%Y-%m');

SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, c.Gender, COUNT(DISTINCT t.ID_client) as count_clients, 
COUNT(DISTINCT t.ID_client) / (SELECT COUNT(DISTINCT t2.ID_client) FROM transactions t2) * 100 as client_share, 
SUM(t.Sum_payment) / (SELECT SUM(t2.Sum_payment) FROM transactions t2) * 100 as payment_share
FROM transactions t
JOIN customers c ON t.ID_client = c.ID_client
GROUP BY month, c.Gender
ORDER BY month;

#3
WITH age_groups AS (
    SELECT 
        CASE 
            WHEN AGE IS NULL THEN 'Unknown'
            WHEN AGE BETWEEN 0 AND 9 THEN '0-9'
            WHEN AGE BETWEEN 10 AND 19 THEN '10-19'
            WHEN AGE BETWEEN 20 AND 29 THEN '20-29'
            WHEN AGE BETWEEN 30 AND 39 THEN '30-39'
            WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
            WHEN AGE BETWEEN 50 AND 59 THEN '50-59'
            WHEN AGE BETWEEN 60 AND 69 THEN '60-69'
            WHEN AGE BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_group,
        c.ID_client,
        t.date_new,
        t.Sum_payment,
        t.Id_check
    FROM Customers c
    JOIN Transactions t ON c.ID_client = t.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
quarterly_stats AS (
    SELECT 
        age_group,
        QUARTER(t.date_new) AS quarter,
        COUNT(DISTINCT t.Id_check) AS operations_count, 
        SUM(t.Sum_payment) AS total_sum,  
        COUNT(DISTINCT t.ID_client) AS clients_count,   
        AVG(t.Sum_payment) AS avg_sum_per_operation    
    FROM age_groups t
    GROUP BY age_group, QUARTER(t.date_new) 
),
annual_stats AS (
    SELECT 
        age_group,
        COUNT(DISTINCT t.Id_check) AS total_operations_year,  
        SUM(t.Sum_payment) AS total_sum_year,  
        COUNT(DISTINCT t.ID_client) AS total_clients_year   
    FROM age_groups t
    GROUP BY age_group
)
SELECT 
    qs.age_group,
    qs.quarter,
    SUM(qs.operations_count) AS quarterly_operations,     
    SUM(qs.total_sum) AS quarterly_sum,        
    AVG(qs.avg_sum_per_operation) AS avg_sum_per_operation,    
    SUM(qs.clients_count) AS clients_per_quarter,              
    SUM(qs.operations_count) / ast.total_operations_year * 100 AS operation_share_quarter, 
    SUM(qs.total_sum) / ast.total_sum_year * 100 AS sum_share_quarter                     
FROM quarterly_stats qs
JOIN annual_stats ast ON qs.age_group = ast.age_group
GROUP BY qs.age_group, qs.quarter 
ORDER BY qs.age_group, qs.quarter;