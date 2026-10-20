-- Migration 003: Add performance indexes for reviews
-- UP:
CREATE INDEX IF NOT EXISTS idx_danhgia_maquan_ngaynhanxet ON danhgia(maquan, ngaynhanxet DESC);
CREATE INDEX IF NOT EXISTS idx_danhgia_makhachhang ON danhgia(makhachhang);
CREATE INDEX IF NOT EXISTS idx_danhgia_mon_mamon ON danhgia_mon(mamon);

-- DOWN:
-- DROP INDEX IF EXISTS idx_danhgia_mon_mamon;
-- DROP INDEX IF EXISTS idx_danhgia_makhachhang;
-- DROP INDEX IF EXISTS idx_danhgia_maquan_ngaynhanxet;
