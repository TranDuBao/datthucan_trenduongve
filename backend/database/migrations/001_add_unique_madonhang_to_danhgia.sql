-- Migration 001: Add UNIQUE constraint to danhgia.madonhang
-- UP:
ALTER TABLE danhgia ADD CONSTRAINT uq_danhgia_madonhang UNIQUE (madonhang);

-- DOWN:
-- ALTER TABLE danhgia DROP CONSTRAINT IF EXISTS uq_danhgia_madonhang;
