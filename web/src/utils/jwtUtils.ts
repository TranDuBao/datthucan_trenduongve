export interface JwtPayload {
  sub?: number;
  email?: string;
  role?: string;
  exp?: number;
  iat?: number;
  [key: string]: any;
}

/**
 * An toàn giải mã JWT Token (Base64Url decode) không cần thư viện ngoài
 */
export function parseJwt(token: string | null): JwtPayload | null {
  if (!token || typeof token !== 'string') return null;
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;

    const base64Url = parts[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      window
        .atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );

    return JSON.parse(jsonPayload);
  } catch (e) {
    return null;
  }
}

/**
 * Kiểm tra xem JWT token đã hết hạn (exp) hay chưa
 */
export function isTokenExpired(token: string | null): boolean {
  const payload = parseJwt(token);
  if (!payload || !payload.exp) return true;
  const currentTime = Math.floor(Date.now() / 1000);
  return payload.exp < currentTime;
}

/**
 * Trích xuất vai trò (Role) trực tiếp từ JWT Claim hợp lệ
 */
export function getUserRoleFromToken(token: string | null): string | null {
  const payload = parseJwt(token);
  if (!payload || isTokenExpired(token)) return null;
  return payload.role || null;
}
