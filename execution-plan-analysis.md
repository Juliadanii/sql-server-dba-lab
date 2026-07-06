# Execution Plan Analysis Notes

Findings from analyzing execution plans for the queries in
`03-performance-tuning/02_query_optimization.sql`, run against the
RetailOps database with ~50,000 rows in `Sales.Orders`.

## Case 1: Non-SARGable date predicate

**Problem.** Filtering with `YEAR(OrderDate) = 2025 AND MONTH(OrderDate) = 2`
wraps the indexed column in functions, so the optimizer cannot seek on
`IX_Orders_OrderDate` and falls back to scanning the whole index.

| Metric | Before (scan) | After (seek) |
|---|---|---|
| Operator | Index Scan | Index Seek |
| Logical reads | ~230 | ~12 |
| Rows read | 50,000 | ~3,900 |

**Fix.** Rewrite as an open-ended date range
(`>= '2025-02-01' AND < '2025-03-01'`), which is SARGable and also handles
the month boundary correctly regardless of time components.

## Case 2: Key lookups from SELECT *

**Problem.** `SELECT * ... WHERE CustomerID = 3` seeks on
`IX_Orders_CustomerID` but then performs a Key Lookup into the clustered
index for every matching row to fetch the remaining columns. At ~10,000
matching rows, the lookup cost dominated the plan (~97% of cost).

**Fix.** Select only the columns the report needs. `OrderDate` and
`OrderStatus` are INCLUDE columns on the index, so the query becomes a
single covered seek. Alternative considered: widening the index — rejected
because the covered-query rewrite was free and the table is write-heavy.

## Case 3: Implicit conversion

**Problem.** Comparing the `VARCHAR` column `OrderStatus` to a unicode
literal `N'Pending'` produces `CONVERT_IMPLICIT` on the column side,
disabling the seek. The plan shows a warning icon on the SELECT operator
and a scan below it.

**Fix.** Use a matching `'Pending'` literal. In application code, this maps
to declaring the parameter as `VARCHAR` rather than `NVARCHAR`.

## Case 4: Missing index for the revenue report

**Problem.** The monthly revenue query filtered on `OrderStatus` and
grouped by month. The plan suggested a missing index with an estimated
impact of ~85%.

**Fix.** Created `IX_Orders_Status_Date (OrderStatus, OrderDate) INCLUDE
(CustomerID)` after checking `sys.dm_db_index_usage_stats` to confirm the
write overhead was acceptable. Post-index, the plan replaced a
hash-match-over-scan with a seek + stream aggregate.

## General workflow used

1. Capture the actual execution plan (`Ctrl+M` in SSMS) and
   `SET STATISTICS IO/TIME ON` output.
2. Look for scans where seeks are expected, thick arrows (row volume),
   key lookups, implicit-conversion warnings, and spills.
3. Prefer query rewrites over new indexes; validate any new index against
   `sys.dm_db_missing_index_details` impact and write cost.
4. Re-measure logical reads after each change to confirm the improvement.
