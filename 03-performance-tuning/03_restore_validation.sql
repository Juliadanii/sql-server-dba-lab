/* =============================================================
   SQL Server DBA Lab - Backup & Recovery: Restore Validation
   Tests the recovery chain by restoring FULL + DIFF into a
   separate database (RetailOps_Restored), then comparing row
   counts against production. An untested backup is not a
   backup — this script is the "test restore procedures" step.
   =============================================================
   NOTE: Replace the file names below with the actual backup
   files produced by scripts 01 and 02.
   ============================================================= */

USE master;
GO

-- ----------------------------------------------------------------
-- Step 1: Restore the FULL backup WITH NORECOVERY
-- (leaves the database ready to accept the differential)
-- ----------------------------------------------------------------
RESTORE DATABASE RetailOps_Restored
FROM DISK = 'C:\SQLBackups\RetailOps_FULL_20250301_010000.bak'
WITH
    MOVE 'RetailOps_Data' TO 'C:\SQLData\RetailOps_Restored_Data.mdf',
    MOVE 'RetailOps_Log'  TO 'C:\SQLLogs\RetailOps_Restored_Log.ldf',
    NORECOVERY,
    CHECKSUM,
    STATS = 10;
GO

-- ----------------------------------------------------------------
-- Step 2: Apply the most recent DIFFERENTIAL, then recover
-- ----------------------------------------------------------------
RESTORE DATABASE RetailOps_Restored
FROM DISK = 'C:\SQLBackups\RetailOps_DIFF_20250301_070000.bak'
WITH RECOVERY, CHECKSUM, STATS = 10;
GO

-- ----------------------------------------------------------------
-- Step 3: Validate — row counts must match the source database
-- ----------------------------------------------------------------
SELECT 'Source' AS Env, 'Orders' AS TableName, COUNT(*) AS Rows
FROM RetailOps.Sales.Orders
UNION ALL
SELECT 'Restored', 'Orders', COUNT(*)
FROM RetailOps_Restored.Sales.Orders
UNION ALL
SELECT 'Source', 'OrderDetails', COUNT(*)
FROM RetailOps.Sales.OrderDetails
UNION ALL
SELECT 'Restored', 'OrderDetails', COUNT(*)
FROM RetailOps_Restored.Sales.OrderDetails;
GO

-- ----------------------------------------------------------------
-- Step 4: Integrity check on the restored copy
-- ----------------------------------------------------------------
DBCC CHECKDB ('RetailOps_Restored') WITH NO_INFOMSGS;
GO

-- ----------------------------------------------------------------
-- Step 5: Clean up the test restore
-- ----------------------------------------------------------------
-- DROP DATABASE RetailOps_Restored;
GO
