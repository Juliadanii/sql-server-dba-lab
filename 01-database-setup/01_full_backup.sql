/* =============================================================
   SQL Server DBA Lab - Backup & Recovery: Full Backup
   Takes a compressed, checksummed full backup and verifies it.
   Schedule in production: nightly at 01:00 via SQL Agent.
   ============================================================= */

USE master;
GO

DECLARE @BackupFile NVARCHAR(260) =
    'C:\SQLBackups\RetailOps_FULL_'
    + FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss') + '.bak';

BACKUP DATABASE RetailOps
TO DISK = @BackupFile
WITH
    COMPRESSION,          -- reduce storage footprint
    CHECKSUM,             -- detect corruption at backup time
    STATS = 10,           -- progress reporting every 10%
    NAME = 'RetailOps Full Backup';

-- Verify the backup is restorable without actually restoring
RESTORE VERIFYONLY
FROM DISK = @BackupFile
WITH CHECKSUM;
GO

-- Review backup history for this database
SELECT TOP 10
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type            AS BackupType,   -- D = Full, I = Differential, L = Log
    CAST(bs.backup_size / 1048576.0 AS DECIMAL(10,2))            AS SizeMB,
    CAST(bs.compressed_backup_size / 1048576.0 AS DECIMAL(10,2)) AS CompressedMB,
    bmf.physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'RetailOps'
ORDER BY bs.backup_start_date DESC;
GO
