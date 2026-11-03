// Production Data Reconciliation Script
// Syncs cuahang.danhgiatrungbinh and cuahang.soluongdanhgia with true ratings from danhgia table
const { Client } = require('pg');

async function applyReconcile() {
  const client = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || '123456',
    database: process.env.DB_DATABASE || 'postgres',
  });

  try {
    await client.connect();
    console.log('=== BẮT ĐẦU ĐỒNG BỘ DỮ LIỆU ĐÁNH GIÁ VÀO BẢNG CUAHANG ===\n');

    // 1. Identify rows to update
    const checkQuery = `
      SELECT 
        c.maquan,
        c.tenquan,
        c.danhgiatrungbinh AS old_avg,
        c.soluongdanhgia AS old_count,
        COALESCE(ROUND(AVG(d.soluongsao)::numeric, 2), 0.00) AS new_avg,
        COUNT(d.madanhgia)::int AS new_count
      FROM cuahang c
      LEFT JOIN danhgia d ON c.maquan = d.maquan AND (d.is_hidden IS NOT TRUE OR d.is_hidden IS NULL)
      GROUP BY c.maquan, c.tenquan, c.danhgiatrungbinh, c.soluongdanhgia
      HAVING (c.danhgiatrungbinh != COALESCE(ROUND(AVG(d.soluongsao)::numeric, 2), 0.00))
          OR (c.soluongdanhgia != COUNT(d.madanhgia)::int)
      ORDER BY c.maquan;
    `;

    const toUpdate = (await client.query(checkQuery)).rows;
    console.log(`Tìm thấy ${toUpdate.length} quán cần cập nhật dữ liệu:`);
    console.table(toUpdate);

    if (toUpdate.length === 0) {
      console.log('Tất cả dữ liệu đã hoàn toàn đồng bộ, không cần cập nhật.');
      return;
    }

    // 2. Perform the update in a transaction
    await client.query('BEGIN');

    const updateQuery = `
      UPDATE cuahang c
      SET 
        danhgiatrungbinh = sub.new_avg,
        soluongdanhgia = sub.new_count
      FROM (
        SELECT 
          ch.maquan,
          COALESCE(ROUND(AVG(dg.soluongsao)::numeric, 2), 0.00) AS new_avg,
          COUNT(dg.madanhgia)::int AS new_count
        FROM cuahang ch
        LEFT JOIN danhgia dg ON ch.maquan = dg.maquan AND (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)
        GROUP BY ch.maquan
      ) sub
      WHERE c.maquan = sub.maquan
        AND (c.danhgiatrungbinh != sub.new_avg OR c.soluongdanhgia != sub.new_count);
    `;

    const updateStoreResult = await client.query(updateQuery);
    console.log(`\n=> Cập nhật thành công ${updateStoreResult.rowCount} dòng trong bảng cuahang.`);

    // 2b. Update monan table
    console.log('\n--- Đang cập nhật bảng monan ---');
    const updateDishQuery = `
      UPDATE monan m
      SET 
        diemdanhgiatb = sub.new_avg,
        soluotdanhgia = sub.new_count
      FROM (
        WITH dish_real_reviews AS (
          SELECT 
            dgm.mamon as mamonan,
            COUNT(DISTINCT dg.madanhgia) as real_count,
            ROUND(AVG(dgm.soluongsao)::numeric, 1) as real_avg
          FROM danhgia_mon dgm
          JOIN danhgia dg ON dg.madanhgia = dgm.madanhgia
          WHERE (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)
          GROUP BY dgm.mamon
        )
        SELECT 
          mo.mamonan,
          COALESCE(r.real_avg, 0.0) as new_avg,
          COALESCE(r.real_count, 0) as new_count
        FROM monan mo
        LEFT JOIN dish_real_reviews r ON r.mamonan = mo.mamonan
      ) sub
      WHERE m.mamonan = sub.mamonan
        AND (m.diemdanhgiatb != sub.new_avg OR m.soluotdanhgia != sub.new_count);
    `;

    const updateDishResult = await client.query(updateDishQuery);
    console.log(`=> Cập nhật thành công ${updateDishResult.rowCount} dòng trong bảng monan.`);

    await client.query('COMMIT');

    // 3. Verify all stores now match
    const verifyQuery = `
      SELECT 
        c.maquan,
        c.tenquan,
        c.danhgiatrungbinh AS db_stored_avg,
        c.soluongdanhgia AS db_stored_count,
        COALESCE(ROUND(AVG(d.soluongsao)::numeric, 2), 0.00) AS real_avg,
        COUNT(d.madanhgia)::int AS real_count
      FROM cuahang c
      LEFT JOIN danhgia d ON c.maquan = d.maquan AND (d.is_hidden IS NOT TRUE OR d.is_hidden IS NULL)
      WHERE (c.is_deleted IS NULL OR c.is_deleted = false)
        AND (c.trangthai IS NULL OR UPPER(c.trangthai) NOT IN ('ĐÃ XÓA', 'DA_XOA', 'DELETED'))
      GROUP BY c.maquan, c.tenquan, c.danhgiatrungbinh, c.soluongdanhgia
      ORDER BY c.maquan;
    `;

    const verifyRows = (await client.query(verifyQuery)).rows;
    console.log('\n=== KẾT QUẢ SAU KHI ĐỒNG BỘ: ===');
    console.table(verifyRows.map(r => ({
      maQuan: r.maquan,
      tenQuan: r.tenquan,
      stored: `${r.db_stored_avg} (${r.db_stored_count} lượt)`,
      real: `${r.real_avg} (${r.real_count} lượt)`,
      khop: (parseFloat(r.db_stored_avg) === parseFloat(r.real_avg) && parseInt(r.db_stored_count, 10) === parseInt(r.real_count, 10)) ? '100% KHỚP' : 'LỆCH',
    })));

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Lỗi trong quá trình cập nhật:', err);
  } finally {
    await client.end();
  }
}

applyReconcile();
