# SQL Server Database Administration Lab

A hands-on DBA lab built on **SQL Server 2022 Developer Edition**, covering the
core responsibilities of a junior database administrator: schema design,
security, backup/recovery, and performance tuning. Built January–March 2025.

## What this lab covers

**1. Database design & configuration** (`01-database-setup/`)
- Created the `RetailOps` database with separate data/log files and FULL recovery model
- Designed a normalized 4-table retail schema (Customers, Products, Orders, OrderDetails) with primary keys, foreign keys, CHECK/DEFAULT/UNIQUE constraints
- Added nonclustered indexes (including a filtered index and covering indexes) based on expected query patterns
- Implemented least-privilege security with database roles: read-only analysts, an app account without DELETE rights, and a junior DBA role limited to backups and monitoring
- Seeded 50,000+ orders set-based (no loops) to make performance work meaningful

**2. Backup & recovery** (`02-backup-recovery/`)
- Full, differential, and transaction log backups with `COMPRESSION` and `CHECKSUM`
- `RESTORE VERIFYONLY` validation on every backup
- Tested the complete recovery chain by restoring FULL + DIFF into a separate database, then validating row counts and running `DBCC CHECKDB`
- Strategy: nightly full + 6-hour differentials + 15-minute log backups → ~15 minute worst-case data loss window

**3. Performance monitoring & tuning** (`03-performance-tuning/`)
- DMV-based monitoring: top queries by CPU, missing/unused indexes, wait statistics, index fragmentation
- Execution plan analysis of four common anti-patterns, with before/after measurements:

| Case | Issue | Result |
|---|---|---|
| Non-SARGable predicate | `YEAR(OrderDate) = 2025` | Scan → Seek, ~230 → ~12 logical reads |
| `SELECT *` | Key lookup per row | Covered index seek, no lookups |
| Implicit conversion | `N'...'` vs VARCHAR | Seek restored |
| Missing index | Revenue report scan | Seek + stream aggregate |

Full analysis notes: [docs/execution-plan-analysis.md](docs/execution-plan-analysis.md)

## Repository structure

```
├── 01-database-setup/
│   ├── 01_create_database.sql      # DB creation, recovery model
│   ├── 02_create_tables.sql        # Schema, tables, keys, constraints
│   ├── 03_indexes.sql              # Nonclustered/filtered/covering indexes
│   ├── 04_user_permissions.sql     # Logins, users, roles, least privilege
│   └── 05_seed_data.sql            # Sample data + 50K row volume load
├── 02-backup-recovery/
│   ├── 01_full_backup.sql
│   ├── 02_differential_backup.sql
│   └── 03_restore_validation.sql   # Test restore + DBCC CHECKDB
├── 03-performance-tuning/
│   ├── 01_monitoring_queries.sql   # DMV health checks
│   └── 02_query_optimization.sql   # Before/after tuning cases
└── docs/
    └── execution-plan-analysis.md  # Plan analysis writeup
```

## How to run it

1. Install [SQL Server 2022 Developer Edition](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) (free) and SQL Server Management Studio
2. Create folders `C:\SQLData`, `C:\SQLLogs`, `C:\SQLBackups` (or edit the paths in the scripts)
3. Run the scripts in `01-database-setup/` in numeric order
4. Run the backup scripts, then update the file names in `03_restore_validation.sql` to match your backup files
5. Run the performance scripts with **Include Actual Execution Plan** (Ctrl+M) enabled in SSMS

## Tools

SQL Server 2022 Developer Edition · SQL Server Management Studio (SSMS) · T-SQL · Dynamic Management Views (DMVs)
