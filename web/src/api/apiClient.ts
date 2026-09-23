const BASE_URL = 'http://localhost:3000/api/v1';

export async function apiFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<{ statusCode: number; status?: string; message?: string; data?: T; payload?: T }> {
  const token = localStorage.getItem('auth_token');

  const headers: Record<String, string> = {
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
    throw new Error(json.message || `Lỗi yêu cầu API (${response.status})`);
  }

  return json;
}
