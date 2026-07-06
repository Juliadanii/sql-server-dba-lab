/* =============================================================
   SQL Server DBA Lab - Step 2: Schema & Tables
   Builds a normalized retail schema: Customers, Products,
   Orders, OrderDetails. Primary keys, foreign keys, CHECK,
   DEFAULT, and UNIQUE constraints are defined inline.
   ============================================================= */

USE RetailOps;
GO

CREATE SCHEMA Sales AUTHORIZATION dbo;
GO

-- -------------------------------------------------------------
-- Customers
-- -------------------------------------------------------------
CREATE TABLE Sales.Customers
(
    CustomerID      INT IDENTITY(1,1)   NOT NULL,
    FirstName       NVARCHAR(50)        NOT NULL,
    LastName        NVARCHAR(50)        NOT NULL,
    Email           NVARCHAR(120)       NOT NULL,
    Phone           VARCHAR(20)         NULL,
    State           CHAR(2)             NULL,
    CreatedDate     DATETIME2(0)        NOT NULL
        CONSTRAINT DF_Customers_CreatedDate DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerID),
    CONSTRAINT UQ_Customers_Email UNIQUE (Email)
);
GO

-- -------------------------------------------------------------
-- Products
-- -------------------------------------------------------------
CREATE TABLE Sales.Products
(
    ProductID       INT IDENTITY(1,1)   NOT NULL,
    ProductName     NVARCHAR(100)       NOT NULL,
    Category        NVARCHAR(50)        NOT NULL,
    UnitPrice       DECIMAL(10,2)       NOT NULL,
    UnitsInStock    INT                 NOT NULL
        CONSTRAINT DF_Products_UnitsInStock DEFAULT 0,
    Discontinued    BIT                 NOT NULL
        CONSTRAINT DF_Products_Discontinued DEFAULT 0,

    CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (ProductID),
    CONSTRAINT CK_Products_UnitPrice CHECK (UnitPrice >= 0),
    CONSTRAINT CK_Products_UnitsInStock CHECK (UnitsInStock >= 0)
);
GO

-- -------------------------------------------------------------
-- Orders
-- -------------------------------------------------------------
CREATE TABLE Sales.Orders
(
    OrderID         INT IDENTITY(1000,1) NOT NULL,
    CustomerID      INT                  NOT NULL,
    OrderDate       DATETIME2(0)         NOT NULL
        CONSTRAINT DF_Orders_OrderDate DEFAULT SYSDATETIME(),
    OrderStatus     VARCHAR(15)          NOT NULL
        CONSTRAINT DF_Orders_Status DEFAULT 'Pending',

    CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (OrderID),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerID)
        REFERENCES Sales.Customers (CustomerID),
    CONSTRAINT CK_Orders_Status CHECK
        (OrderStatus IN ('Pending','Shipped','Delivered','Cancelled'))
);
GO

-- -------------------------------------------------------------
-- OrderDetails (line items)
-- -------------------------------------------------------------
CREATE TABLE Sales.OrderDetails
(
    OrderID         INT             NOT NULL,
    ProductID       INT             NOT NULL,
    Quantity        INT             NOT NULL,
    UnitPrice       DECIMAL(10,2)   NOT NULL,

    CONSTRAINT PK_OrderDetails PRIMARY KEY CLUSTERED (OrderID, ProductID),
    CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderID)
        REFERENCES Sales.Orders (OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderDetails_Products FOREIGN KEY (ProductID)
        REFERENCES Sales.Products (ProductID),
    CONSTRAINT CK_OrderDetails_Quantity CHECK (Quantity > 0)
);
GO

-- Verify all four tables exist
SELECT s.name AS SchemaName, t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY t.name;
GO
