const envApiUrl = (import.meta as any).env?.VITE_API_URL;
export const API_HOST = envApiUrl ? envApiUrl.replace(/\/+$/, '').replace(/\/api\/v1$/, '') : 'http://localhost:3000';
export const API_BASE_URL = `${API_HOST}/api/v1`;
const BASE_URL = API_BASE_URL;

export interface ApiResponse<T = any> {
  statusCode: number;
  status?: string;
  message?: string;
  data?: T;
  payload?: T;
  [key: string]: any;
}

export async function apiFetch<T = any>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  const token = localStorage.getItem('auth_token');

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  const text = await response.text();
  let json: any = {};
  try {
    json = JSON.parse(text);
  } catch (e) {
    if (!response.ok) {
      throw new Error(`Lỗi server (${response.status}): Đường dẫn ${endpoint} không trả về dữ liệu JSON.`);
    }
  }

  if (!response.ok) {
    if (response.status === 401) {
      localStorage.removeItem('auth_token');
      localStorage.removeItem('auth_user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    throw new Error(json.message || `Lỗi yêu cầu API (${response.status})`);
  }

  return json;
}
