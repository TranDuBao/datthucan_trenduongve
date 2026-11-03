/**
 * DRY-RUN RATING RECONCILIATION SCRIPT
 * Audits discrepancy between stored rating columns and actual reviews.
 * ONLY READS AND PRINTS - NEVER WRITES TO DATABASE.
 */

const { Client } = require('pg');

async function dryRunReconcile() {
  const targetDb = process.env.DRY_RUN_DB || 'postgres';
  const targetUser = process.env.DRY_RUN_USER || 'readonly_user';
  const targetPass = process.env.DRY_RUN_PASS || 'readonly_pass';

  console.log('======================================================================');
  console.log(`[DRY-RUN] Auditing Ratings on Database: ${targetDb} (User: ${targetUser})`);
  console.log('Mode: READ-ONLY (No modifications will be made)');
  console.log('======================================================================\n');

  const client = new Client({
    host: 'host.docker.internal',
    port: 5432,
    user: targetUser,
    password: targetPass,
    database: targetDb,
  });

  await client.connect();

  try {
    // 1. Audit Stores
    console.log('--- [1] Rà soát Cửa hàng (cuahang.danhgiatrungbinh, cuahang.soluongdanhgia) ---');
    const storeQuery = `
      SELECT 
        c.maquan,
        c.tenquan,
        c.danhgiatrungbinh as current_avg,
        c.soluongdanhgia as current_count,
        COUNT(dg.madanhgia) as real_count,
        ROUND(COALESCE(AVG(dg.soluongsao), 0)::numeric, 2) as real_avg
      FROM cuahang c
      LEFT JOIN danhgia dg ON dg.maquan = c.maquan AND (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)
      GROUP BY c.maquan, c.tenquan, c.danhgiatrungbinh, c.soluongdanhgia
      HAVING c.soluongdanhgia != COUNT(dg.madanhgia)
         OR (COUNT(dg.madanhgia) > 0 AND c.danhgiatrungbinh != ROUND(AVG(dg.soluongsao)::numeric, 2))
         OR (COUNT(dg.madanhgia) = 0 AND c.danhgiatrungbinh > 0)
      ORDER BY c.maquan;
    `;

    const storeDiscrepancies = await client.query(storeQuery);
    if (storeDiscrepancies.rows.length === 0) {
      console.log('  -> 100% Cửa hàng đã khớp với bảng đánh giá thật. Không có thay đổi.');
    } else {
      console.log(`  -> Phát hiện ${storeDiscrepancies.rows.length} cửa hàng bị lệch dữ liệu:`);
      for (const s of storeDiscrepancies.rows) {
        console.log(`     * Quán #${s.maquan} [${s.tenquan}]:`);
        console.log(`       - Hiện tại lưu : ${s.current_avg} sao (${s.current_count} lượt)`);
        console.log(`       - Tính lại thật: ${s.real_avg} sao (${s.real_count} lượt)`);
        console.log(`       - Lệnh đề xuất : UPDATE cuahang SET danhgiatrungbinh = ${s.real_avg}, soluongdanhgia = ${s.real_count} WHERE maquan = ${s.maquan};`);
      }
    }

    // 2. Audit Dishes
    console.log('\n--- [2] Rà soát Món ăn (monan.diemdanhgiatb, monan.soluotdanhgia) ---');
    const dishQuery = `
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
        m.mamonan,
        m.maquan,
        m.tenmonan,
        m.diemdanhgiatb as current_avg,
        m.soluotdanhgia as current_count,
        COALESCE(r.real_count, 0) as real_count,
        COALESCE(r.real_avg, 0.0) as real_avg
      FROM monan m
      LEFT JOIN dish_real_reviews r ON r.mamonan = m.mamonan
      WHERE m.soluotdanhgia != COALESCE(r.real_count, 0)
         OR (COALESCE(r.real_count, 0) = 0 AND m.diemdanhgiatb > 0)
         OR (COALESCE(r.real_count, 0) > 0 AND m.diemdanhgiatb != r.real_avg)
      ORDER BY m.maquan, m.mamonan;
    `;

    const dishDiscrepancies = await client.query(dishQuery);
    if (dishDiscrepancies.rows.length === 0) {
      console.log('  -> 100% Món ăn đã khớp với bảng đánh giá thật. Không có thay đổi.');
    } else {
      console.log(`  -> Phát hiện ${dishDiscrepancies.rows.length} món ăn bị lệch dữ liệu:`);
      for (const d of dishDiscrepancies.rows) {
        console.log(`     * Món #${d.mamonan} [${d.tenmonan}] (Quán #${d.maquan}):`);
        console.log(`       - Hiện tại lưu : ${d.current_avg} sao (${d.current_count} lượt)`);
        console.log(`       - Tính lại thật: ${d.real_avg} sao (${d.real_count} lượt)`);
        console.log(`       - Lệnh đề xuất : UPDATE monan SET diemdanhgiatb = ${d.real_avg}, soluotdanhgia = ${d.real_count} WHERE mamonan = ${d.mamonan};`);
      }
    }

    console.log('\n======================================================================');
    console.log(`[DRY-RUN KẾT THÚC] Tổng số bản ghi cần đối soát: ${storeDiscrepancies.rows.length} quán, ${dishDiscrepancies.rows.length} món.`);
    console.log('LƯU Ý: Không có lệnh ghi nào được thực thi. Chờ người dùng duyệt trước khi chạy apply.');
    console.log('======================================================================');

  } finally {
    await client.end();
  }
}

dryRunReconcile().catch((err) => {
  console.error('Dry-run audit error:', err);
  process.exit(1);
});
