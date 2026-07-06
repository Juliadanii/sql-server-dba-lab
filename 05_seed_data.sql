/* =============================================================
   SQL Server DBA Lab - Step 5: Seed Sample Data
   Loads a small set of realistic rows plus a volume load of
   orders (50,000 rows) so that index and execution-plan work
   in 03-performance-tuning has meaningful data to run against.
   ============================================================= */

USE RetailOps;
GO

-- -------------------------------------------------------------
-- Customers
-- -------------------------------------------------------------
INSERT INTO Sales.Customers (FirstName, LastName, Email, Phone, State)
VALUES
    ('Amina',  'Bekele',   'amina.bekele@example.com',  '410-555-0141', 'MD'),
    ('Marcus', 'Rivera',   'marcus.rivera@example.com', '443-555-0182', 'MD'),
    ('Priya',  'Sharma',   'priya.sharma@example.com',  '650-555-0119', 'CA'),
    ('Daniel', 'Okafor',   'daniel.okafor@example.com', '301-555-0163', 'VA'),
    ('Elena',  'Petrov',   'elena.petrov@example.com',  '408-555-0177', 'CA');
GO

-- -------------------------------------------------------------
-- Products
-- -------------------------------------------------------------
INSERT INTO Sales.Products (ProductName, Category, UnitPrice, UnitsInStock)
VALUES
    ('Mechanical Keyboard',   'Electronics',  89.99, 120),
    ('Wireless Mouse',        'Electronics',  34.50, 300),
    ('Standing Desk',         'Furniture',   449.00,  45),
    ('Ergonomic Chair',       'Furniture',   329.99,  60),
    ('USB-C Dock',            'Electronics', 129.00,  85),
    ('Desk Lamp',             'Furniture',    39.99, 150),
    ('Noise-Cancel Headset',  'Electronics', 199.99,  75),
    ('Monitor 27in',          'Electronics', 279.00,  90);
GO

-- -------------------------------------------------------------
-- Volume load: 50,000 orders + line items over a 12-month span
-- Uses a numbers CTE to generate rows set-based (no loops).
-- -------------------------------------------------------------
;WITH N AS
(
    SELECT TOP (50000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO Sales.Orders (CustomerID, OrderDate, OrderStatus)
SELECT
    (n % 5) + 1,
    DATEADD(MINUTE, -(n * 11), SYSDATETIME()),
    CASE n % 10
        WHEN 0 THEN 'Cancelled'
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Shipped'
        ELSE 'Delivered'
    END
FROM N;
GO

-- One or two line items per order
INSERT INTO Sales.OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
SELECT
    o.OrderID,
    (o.OrderID % 8) + 1,
    (o.OrderID % 3) + 1,
    p.UnitPrice
FROM Sales.Orders o
JOIN Sales.Products p ON p.ProductID = (o.OrderID % 8) + 1;
GO

INSERT INTO Sales.OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
SELECT
    o.OrderID,
    ((o.OrderID + 3) % 8) + 1,
    1,
    p.UnitPrice
FROM Sales.Orders o
JOIN Sales.Products p ON p.ProductID = ((o.OrderID + 3) % 8) + 1
WHERE o.OrderID % 2 = 0;
GO

-- Row counts for verification
SELECT 'Customers' AS TableName, COUNT(*) AS Rows FROM Sales.Customers
UNION ALL SELECT 'Products',     COUNT(*) FROM Sales.Products
UNION ALL SELECT 'Orders',       COUNT(*) FROM Sales.Orders
UNION ALL SELECT 'OrderDetails', COUNT(*) FROM Sales.OrderDetails;
GO
