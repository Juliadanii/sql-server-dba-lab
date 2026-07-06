/* =============================================================
   SQL Server DBA Lab - Performance: Monitoring Queries
   DMV-based health checks used to identify expensive queries,
   missing indexes, and wait-stat pressure before tuning.
   ============================================================= */

USE RetailOps;
GO

-- -------------------------------------------------------------
-- 1. Top 10 most expensive queries by total CPU
-- -------------------------------------------------------------
SELECT TOP 10
    qs.total_worker_time / 1000        AS TotalCpuMs,
    qs.execution_count,
    qs.total_worker_time / qs.execution_count / 1000 AS AvgCpuMs,
    qs.total_logical_reads,
    SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset END
          - qs.statement_start_offset)/2) + 1) AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_worker_time DESC;
GO

-- -------------------------------------------------------------
-- 2. Missing index suggestions (validate before creating!)
-- -------------------------------------------------------------
SELECT
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.user_seeks,
    migs.avg_user_impact,
    migs.user_seeks * migs.avg_user_impact AS ImpactScore
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups mig  ON mid.index_handle = mig.index_handle
JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id = DB_ID('RetailOps')
ORDER BY ImpactScore DESC;
GO

-- -------------------------------------------------------------
-- 3. Index usage: find unused indexes (write cost, no read benefit)
-- -------------------------------------------------------------
SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name                   AS IndexName,
    ius.user_seeks, ius.user_scans, ius.user_lookups,
    ius.user_updates         AS WritesMaintained
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id AND i.index_id = ius.index_id
   AND ius.database_id = DB_ID()
WHERE OBJECT_SCHEMA_NAME(i.object_id) = 'Sales'
  AND i.type_desc = 'NONCLUSTERED'
ORDER BY (ISNULL(ius.user_seeks,0) + ISNULL(ius.user_scans,0)) ASC;
GO

-- -------------------------------------------------------------
-- 4. Current wait statistics (top pressure points)
-- -------------------------------------------------------------
SELECT TOP 10
    wait_type,
    wait_time_ms / 1000.0    AS WaitTimeSec,
    waiting_tasks_count,
    wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS PctOfTotal
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%'
  AND wait_type NOT LIKE 'XE%'
  AND wait_type NOT IN ('BROKER_TASK_STOP','CHECKPOINT_QUEUE',
                        'LAZYWRITER_SLEEP','REQUEST_FOR_DEADLOCK_SEARCH')
ORDER BY wait_time_ms DESC;
GO

-- -------------------------------------------------------------
-- 5. Index fragmentation check (rebuild > 30%, reorganize 5-30%)
-- -------------------------------------------------------------
SELECT
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name                     AS IndexName,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    CASE
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 5  THEN 'REORGANIZE'
        ELSE 'OK'
    END AS Recommendation
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO
