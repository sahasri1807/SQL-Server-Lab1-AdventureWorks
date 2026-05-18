-- Part A — Environment + IF EXISTS

-- A1) Use database
USE AdventureWorks2022;
GO

-- A2) Cleanup using IF EXISTS
DROP TABLE IF EXISTS EntryTest.OrderItemMini;
DROP TABLE IF EXISTS EntryTest.OrderMini;
DROP TABLE IF EXISTS EntryTest.CustomerMini;
GO

-- Part B — DDL Tables + Constraints

-- B1) Create schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'EntryTest')
    EXEC('CREATE SCHEMA EntryTest');
GO

-- B2) Create EntryTest.CustomerMini
CREATE TABLE EntryTest.CustomerMini (
    CustomerMiniID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL UNIQUE,
    AccountNumber NVARCHAR(10) NOT NULL,
    CustomerType NCHAR(1) NOT NULL CHECK (CustomerType IN ('I','S')),
    CreatedAt DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
GO

-- B3) Create EntryTest.OrderMini
CREATE TABLE EntryTest.OrderMini (
    OrderMiniID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL UNIQUE,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    SubTotal MONEY NOT NULL CHECK (SubTotal >= 0),
    TaxAmt MONEY NOT NULL CHECK (TaxAmt >= 0),
    Freight MONEY NOT NULL CHECK (Freight >= 0),
    TotalDue MONEY NOT NULL CHECK (TotalDue >= 0)
);
GO

-- B4) Create EntryTest.OrderItemMini
CREATE TABLE EntryTest.OrderItemMini (
    OrderItemMiniID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    SalesOrderDetailID INT NOT NULL,
    ProductID INT NOT NULL,
    OrderQty SMALLINT NOT NULL CHECK (OrderQty > 0),
    UnitPrice MONEY NOT NULL CHECK (UnitPrice >= 0),
    UnitPriceDiscount MONEY NOT NULL DEFAULT(0) CHECK (UnitPriceDiscount BETWEEN 0 AND 1),
    LineTotal MONEY NOT NULL CHECK (LineTotal >= 0),

    CONSTRAINT UQ_OrderItem UNIQUE (SalesOrderID, SalesOrderDetailID),

    CONSTRAINT FK_OrderItem_Order
        FOREIGN KEY (SalesOrderID)
        REFERENCES EntryTest.OrderMini(SalesOrderID)
);
GO

-- Part C — Basic DML

-- C1) Insert customers
INSERT INTO EntryTest.CustomerMini (CustomerID, AccountNumber, CustomerType)
SELECT TOP 50
    CustomerID,
    AccountNumber,
    CASE 
        WHEN StoreID IS NULL THEN 'I'
        ELSE 'S'
    END AS CustomerType
FROM Sales.Customer
ORDER BY CustomerID ASC;
    
-- C2) Insert orders
INSERT INTO EntryTest.OrderMini (SalesOrderID, CustomerID, OrderDate, SubTotal, TaxAmt, Freight, TotalDue)
SELECT TOP 200
    SalesOrderID,
    CustomerID,
    OrderDate,
    SubTotal,
    TaxAmt,
    Freight,
    TotalDue
FROM Sales.SalesOrderHeader
ORDER BY OrderDate DESC, SalesOrderID DESC;
    
-- C3) Insert order items
INSERT INTO EntryTest.OrderItemMini (
    SalesOrderID,
    SalesOrderDetailID,
    ProductID,
    OrderQty,
    UnitPrice,
    UnitPriceDiscount,
    LineTotal
)
SELECT
    d.SalesOrderID,
    d.SalesOrderDetailID,
    d.ProductID,
    d.OrderQty,
    d.UnitPrice,
    d.UnitPriceDiscount,
    d.LineTotal
FROM Sales.SalesOrderDetail d
WHERE d.SalesOrderID IN (
    SELECT SalesOrderID FROM EntryTest.OrderMini
);

-- Part D — MERGE Upsert

-- D1) MERGE into CustomerMini
MERGE EntryTest.CustomerMini AS target
USING (
    SELECT 
        CustomerID,
        AccountNumber,
        CASE 
            WHEN StoreID IS NULL THEN 'I'
            ELSE 'S'
        END AS CustomerType
    FROM Sales.Customer
    WHERE CustomerID <= 60
) AS source
ON target.CustomerID = source.CustomerID

WHEN MATCHED THEN
    UPDATE SET
        target.AccountNumber = source.AccountNumber,
        target.CustomerType = source.CustomerType

WHEN NOT MATCHED THEN
    INSERT (CustomerID, AccountNumber, CustomerType)
    VALUES (source.CustomerID, source.AccountNumber, source.CustomerType);

-- Part E — UNION / UNION ALL

-- E1) UNION: Combined People Names
SELECT NameValue
FROM (
    SELECT TOP 10 FirstName AS NameValue
    FROM Person.Person
    ORDER BY BusinessEntityID

    UNION

    SELECT TOP 10 LastName
    FROM Person.Person
    ORDER BY BusinessEntityID
) X
ORDER BY NameValue;

-- E2) UNION ALL: Two product lists
SELECT 'FinishedGoods' AS ListType,
       ProductID,
       Name
FROM (
    SELECT TOP 10 ProductID, Name
    FROM Production.Product
    WHERE FinishedGoodsFlag = 1
    ORDER BY ProductID
) A

UNION ALL

SELECT 'NotFinished',
       ProductID,
       Name
FROM (
    SELECT TOP 10 ProductID, Name
    FROM Production.Product
    WHERE FinishedGoodsFlag = 0
    ORDER BY ProductID
) B;

-- Part F — JOIN Queries 
-- F1) INNER JOIN — Orders with Customer Info 
SELECT
    o.SalesOrderID,
    o.OrderDate,
    c.CustomerID,
    c.AccountNumber,
    o.TotalDue
FROM EntryTest.OrderMini o
INNER JOIN EntryTest.CustomerMini c
    ON o.CustomerID = c.CustomerID
ORDER BY o.OrderDate DESC;

-- F2) LEFT JOIN — Customers with or without Orders 
SELECT
    c.CustomerID,
    c.AccountNumber,
    o.SalesOrderID,
    o.OrderDate
FROM EntryTest.CustomerMini c
LEFT JOIN EntryTest.OrderMini o
    ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID ASC;

-- F3) JOIN + GROUP BY — Order Totals per Customer 
SELECT
    CustomerID,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSpent
FROM EntryTest.OrderMini
GROUP BY CustomerID;
