/* =============================================================
   SQL Server DBA Lab - Backup & Recovery: Differential Backup
   Captures all changes since the last FULL backup.
   Schedule in production: every 6 hours via SQL Agent.
   Strategy: nightly full + 6-hour differentials + 15-min log
   backups gives a worst-case data loss window of ~15 minutes.
   ============================================================= */

USE master;
GO

-- Simulate business activity between backups so the
-- differential has something to capture
USE RetailOps;
INSERT INTO Sales.Customers (FirstName, LastName, Email, State)
VALUES ('Test', 'DiffUser', CONCAT('diff_', FORMAT(SYSDATETIME(),'HHmmss'), '@example.com'), 'CA');
GO

USE master;
GO

DECLARE @BackupFile NVARCHAR(260) =
    'C:\SQLBackups\RetailOps_DIFF_'
    + FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss') + '.bak';

BACKUP DATABASE RetailOps
TO DISK = @BackupFile
WITH
    DIFFERENTIAL,
    COMPRESSION,
    CHECKSUM,
    STATS = 25,
    NAME = 'RetailOps Differential Backup';

RESTORE VERIFYONLY FROM DISK = @BackupFile WITH CHECKSUM;
GO

-- Transaction log backup (requires FULL recovery model)
DECLARE @LogFile NVARCHAR(260) =
    'C:\SQLBackups\RetailOps_LOG_'
    + FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss') + '.trn';

BACKUP LOG RetailOps
TO DISK = @LogFile
WITH COMPRESSION, CHECKSUM, STATS = 25,
     NAME = 'RetailOps Log Backup';
GO
