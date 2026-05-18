# SQL-Server-Lab1-AdventureWorks
SQL Server Lab using AdventureWorks2022 with Docker and VS Code

## Overview
This lab uses the AdventureWorks2022 database to practice core SQL Server concepts. The work focuses on building a small reporting structure using custom tables and running queries on top of them.

All operations are done using set-based SQL.

---

## What was implemented

### Tables created
- CustomerMini
- OrderMini
- OrderItemMini

These tables were designed with primary keys, foreign keys, and basic constraints.

---

### Data loading
- First 50 customers were taken from Sales.Customer
- Latest 200 orders were taken from Sales.SalesOrderHeader
- Order details were loaded from Sales.SalesOrderDetail

---

### Operations performed
- MERGE used to update/insert customer data
- INNER JOIN to connect customers and orders
- LEFT JOIN to show customers with and without orders
- GROUP BY to calculate total orders and spending
- UNION / UNION ALL to combine datasets

---

## Tools used
- SQL Server (via Docker)
- VS Code
- AdventureWorks2022 database

---

## File included
- Lab1.sql → full script with all queries

---

## Notes
All objects were created in a separate schema so the original database was not modified.
