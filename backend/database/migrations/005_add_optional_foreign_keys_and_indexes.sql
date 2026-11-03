-- Migration: 005_add_optional_foreign_keys_and_indexes.sql
-- Description: Bổ sung ràng buộc khóa ngoại cho bảng hoàn tiền (hoantien.mathanhtoan -> thanhtoan.mathanhtoan)
--              và index tăng tốc truy vấn lịch sử đơn hàng của khách hàng.
-- CHÚ Ý: FILE NÀY ĐƯỢC TẠO ĐỂ REVIEW, KHÔNG TỰ ĐỘNG CHẠY NẾU CHƯA ĐƯỢC DUYỆT.

-- 1. Bổ sung khóa ngoại từ hoantien.mathanhtoan sang thanhtoan.mathanhtoan (ON DELETE SET NULL an toàn)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_hoantien_thanhtoan'
    ) THEN
        ALTER TABLE hoantien
        ADD CONSTRAINT fk_hoantien_thanhtoan
        FOREIGN KEY (mathanhtoan)
        REFERENCES thanhtoan(mathanhtoan)
        ON DELETE SET NULL;
    END IF;
END $$;

-- 2. Bổ sung Index tăng tốc truy vấn phân trang danh sách đơn hàng theo khách hàng
CREATE INDEX IF NOT EXISTS idx_donhang_khachhang_thoigiandat
ON donhang(makhachhang, thoigiandat DESC);

-- ROLLBACK SCRIPT (Khi cần hoàn tác):
-- ALTER TABLE hoantien DROP CONSTRAINT IF EXISTS fk_hoantien_thanhtoan;
-- DROP INDEX IF EXISTS idx_donhang_khachhang_thoigiandat;
