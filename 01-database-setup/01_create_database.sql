/* =============================================================
   SQL Server DBA Lab - Step 1: Database Creation
   Creates the RetailOps database with separate data and log
   files, sized with growth settings appropriate for a small
   OLTP workload.
   Environment: SQL Server 2022 Developer Edition
   ============================================================= */

USE master;
GO

-- Drop and recreate for repeatable lab runs
IF DB_ID('RetailOps') IS NOT NULL
BEGIN
    ALTER DATABASE RetailOps SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RetailOps;
END
GO

CREATE DATABASE RetailOps
ON PRIMARY
(
    NAME        = RetailOps_Data,
    FILENAME    = 'C:\SQLData\RetailOps_Data.mdf',
    SIZE        = 256MB,
    FILEGROWTH  = 64MB
)
LOG ON
(
    NAME        = RetailOps_Log,
    FILENAME    = 'C:\SQLLogs\RetailOps_Log.ldf',
    SIZE        = 128MB,
    FILEGROWTH  = 64MB
);
GO

-- FULL recovery model so differential + log backups are possible
ALTER DATABASE RetailOps SET RECOVERY FULL;
GO

-- Verify configuration
SELECT name, recovery_model_desc, state_desc
FROM sys.databases
WHERE name = 'RetailOps';
GO
