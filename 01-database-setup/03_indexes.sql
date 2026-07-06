/* =============================================================
   SQL Server DBA Lab - Step 3: Nonclustered Indexes
   Indexes chosen based on expected query patterns:
   - Orders are frequently filtered by CustomerID and OrderDate
   - Products are searched by Category
   - Customers are looked up by LastName
   ============================================================= */

USE RetailOps;
GO

-- Supports "all orders for a customer" lookups and the FK join
CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
    ON Sales.Orders (CustomerID)
    INCLUDE (OrderDate, OrderStatus);
GO

-- Supports date-range reporting queries
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
    ON Sales.Orders (OrderDate);
GO

-- Supports category browsing; filtered to active products only
CREATE NONCLUSTERED INDEX IX_Products_Category
    ON Sales.Products (Category)
    INCLUDE (ProductName, UnitPrice)
    WHERE Discontinued = 0;
GO

-- Supports customer name searches
CREATE NONCLUSTERED INDEX IX_Customers_LastName
    ON Sales.Customers (LastName, FirstName);
GO

-- Review index inventory
SELECT
    OBJECT_NAME(i.object_id)  AS TableName,
    i.name                    AS IndexName,
    i.type_desc               AS IndexType,
    i.has_filter              AS IsFiltered
FROM sys.indexes i
WHERE OBJECT_SCHEMA_NAME(i.object_id) = 'Sales'
  AND i.name IS NOT NULL
ORDER BY TableName, IndexName;
GO
