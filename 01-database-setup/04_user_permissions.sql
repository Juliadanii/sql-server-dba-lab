/* =============================================================
   SQL Server DBA Lab - Step 4: Security & Permissions
   Implements least-privilege access using database roles:
   - ReportingReaders : SELECT only (analysts)
   - SalesAppUsers    : read/write on Sales schema (application)
   - JuniorDBAs       : backup + monitoring rights, no data changes
   ============================================================= */

USE RetailOps;
GO

-- -------------------------------------------------------------
-- Logins (server level) and users (database level)
-- SQL authentication used here for lab purposes;
-- production would typically use Windows/Entra ID auth.
-- -------------------------------------------------------------
USE master;
GO
CREATE LOGIN analyst_reader  WITH PASSWORD = 'Lab_Str0ngPass!1', CHECK_POLICY = ON;
CREATE LOGIN sales_app       WITH PASSWORD = 'Lab_Str0ngPass!2', CHECK_POLICY = ON;
CREATE LOGIN junior_dba      WITH PASSWORD = 'Lab_Str0ngPass!3', CHECK_POLICY = ON;
GO

USE RetailOps;
GO
CREATE USER analyst_reader FOR LOGIN analyst_reader;
CREATE USER sales_app      FOR LOGIN sales_app;
CREATE USER junior_dba     FOR LOGIN junior_dba;
GO

-- -------------------------------------------------------------
-- Roles and grants
-- -------------------------------------------------------------
CREATE ROLE ReportingReaders;
GRANT SELECT ON SCHEMA::Sales TO ReportingReaders;
ALTER ROLE ReportingReaders ADD MEMBER analyst_reader;
GO

CREATE ROLE SalesAppUsers;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Sales TO SalesAppUsers;
-- Deliberately no DELETE: the app soft-deletes via OrderStatus
ALTER ROLE SalesAppUsers ADD MEMBER sales_app;
GO

CREATE ROLE JuniorDBAs;
ALTER ROLE db_backupoperator ADD MEMBER junior_dba;
GRANT VIEW DATABASE STATE TO JuniorDBAs;
ALTER ROLE JuniorDBAs ADD MEMBER junior_dba;
GO

-- -------------------------------------------------------------
-- Validate: check effective permissions per principal
-- -------------------------------------------------------------
SELECT
    pr.name           AS PrincipalName,
    pr.type_desc      AS PrincipalType,
    pe.permission_name,
    pe.state_desc,
    OBJECT_SCHEMA_NAME(pe.major_id) AS SchemaName
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('ReportingReaders','SalesAppUsers','JuniorDBAs')
ORDER BY pr.name;
GO

-- Spot test: impersonate the analyst and confirm writes fail
EXECUTE AS USER = 'analyst_reader';
SELECT TOP 5 * FROM Sales.Customers;          -- succeeds
-- INSERT INTO Sales.Customers ... ;          -- fails: permission denied (expected)
REVERT;
GO
