/**
 * Tiện ích làm sạch thông báo lỗi (Error Sanitizer)
 * Ngăn chặn rò rỉ chi tiết kỹ thuật/database/SQL ra phía người dùng hoặc client
 */
export function sanitizeErrorMessage(error: any, fallback = 'Hệ thống đang gặp lỗi, vui lòng thử lại'): string {
  const rawMsg = typeof error === 'string' ? error : (error?.message || '');
  if (!rawMsg || typeof rawMsg !== 'string') return fallback;

  const msgLower = rawMsg.toLowerCase();

  // Cho phép các thông báo nghiệp vụ rõ ràng, an toàn hiển thị cho người dùng
  if (
    msgLower.includes('email hoặc tên đăng nhập đã tồn tại') ||
    msgLower.includes('tên đăng nhập đã tồn tại') ||
    msgLower.includes('email đã được sử dụng') ||
    msgLower.includes('vui lòng nhập') ||
    msgLower.includes('mật khẩu mới phải có ít nhất') ||
    msgLower.includes('mật khẩu phải có ít nhất') ||
    msgLower.includes('mật khẩu hiện tại không chính xác') ||
    msgLower.includes('tài khoản hoặc mật khẩu không chính xác') ||
    msgLower.includes('tài khoản hiện đang bị khóa') ||
    msgLower.includes('tài khoản chưa xác thực')
  ) {
    return rawMsg;
  }

  // Chuyển đổi lỗi unique constraint của DB thành thông báo thân thiện
  if (msgLower.includes('duplicate key') || msgLower.includes('unique constraint') || msgLower.includes('already exists')) {
    if (msgLower.includes('email') || msgLower.includes('tendangnhap')) {
      return 'Email hoặc tên đăng nhập này đã được đăng ký!';
    }
    if (msgLower.includes('sdt') || msgLower.includes('phone')) {
      return 'Số điện thoại này đã được đăng ký!';
    }
    return 'Thông tin tài khoản đã tồn tại trên hệ thống!';
  }

  // Chặn toàn bộ lỗi Database / SQL / TypeORM / Postgres
  const technicalKeywords = [
    'null value', 'violates', 'constraint', 'relation', 'column',
    'syntax error', 'database', 'sql', 'postgres', 'typeorm',
    'query', 'econnrefused', 'deadlock', 'fatal',
    'connection', 'stack', 'select ', 'insert ', 'update ', 'delete ',
    'table ', 'defaultval', 'nextval', 'prisma', 'sequelize',
    'pg_', 'internal server error', 'cannot read property', 'undefined is not'
  ];

  if (technicalKeywords.some((kw) => msgLower.includes(kw))) {
    return fallback;
  }

  return rawMsg;
}
