/* =============================================================
   SQL Server DBA Lab - Performance: Query Optimization
   Before/after tuning examples run against the 50K-row Orders
   table. Execution plans and STATISTICS IO output for each case
   are documented in ../docs/execution-plan-analysis.md.
   ============================================================= */

USE RetailOps;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- =============================================================
-- CASE 1: Non-SARGable predicate
-- =============================================================

-- BEFORE: wrapping the column in a function prevents index use
-- Plan shows: Index Scan on IX_Orders_OrderDate (reads all rows)
SELECT OrderID, CustomerID, OrderDate
FROM Sales.Orders
WHERE YEAR(OrderDate) = 2025 AND MONTH(OrderDate) = 2;
GO

-- AFTER: rewrite as a range predicate -> Index Seek
-- Logical reads dropped from ~230 to ~12 in lab runs
SELECT OrderID, CustomerID, OrderDate
FROM Sales.Orders
WHERE OrderDate >= '2025-02-01'
  AND OrderDate <  '2025-03-01';
GO

-- =============================================================
-- CASE 2: SELECT * causing key lookups
-- =============================================================

-- BEFORE: SELECT * forces a Key Lookup for every matching row
SELECT *
FROM Sales.Orders
WHERE CustomerID = 3;
GO

-- AFTER: select only needed columns covered by IX_Orders_CustomerID
-- Plan shows a single covered Index Seek, no lookups
SELECT OrderID, OrderDate, OrderStatus
FROM Sales.Orders
WHERE CustomerID = 3;
GO

-- =============================================================
-- CASE 3: Implicit conversion breaking a seek
-- =============================================================

-- BEFORE: N'...' unicode literal vs VARCHAR column causes
-- CONVERT_IMPLICIT and a scan
SELECT OrderID, OrderStatus
FROM Sales.Orders
WHERE OrderStatus = N'Pending';
GO

-- AFTER: match the column's data type
SELECT OrderID, OrderStatus
FROM Sales.Orders
WHERE OrderStatus = 'Pending';
GO

-- =============================================================
-- CASE 4: Aggregation supported by an index
-- =============================================================

-- Revenue by month report query
SELECT
    DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS OrderMonth,
    SUM(od.Quantity * od.UnitPrice) AS Revenue,
    COUNT(DISTINCT o.OrderID)       AS Orders
FROM Sales.Orders o
JOIN Sales.OrderDetails od ON o.OrderID = od.OrderID
WHERE o.OrderStatus = 'Delivered'
GROUP BY DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
ORDER BY OrderMonth;
GO

-- Supporting index created after reviewing the plan's
-- missing-index suggestion (validated against write overhead)
CREATE NONCLUSTERED INDEX IX_Orders_Status_Date
    ON Sales.Orders (OrderStatus, OrderDate)
    INCLUDE (CustomerID);
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
