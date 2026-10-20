-- Migration: 004_add_donhang_pagination_index.sql
-- Description: Composite index to optimize ORDER BY and pagination on the orders table
-- Fields: thoigiandat DESC, madonhang DESC

CREATE INDEX IF NOT EXISTS idx_donhang_thoigiandat_madonhang
ON donhang (thoigiandat DESC, madonhang DESC);
