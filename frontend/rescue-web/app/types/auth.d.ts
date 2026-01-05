export interface User {
  id: string;
  email: string;
  phone: string | null;
  role?: string; // Dựa vào token decode nếu cần, hoặc BE trả thêm
}

export interface AuthResponse {
  token: {
    access_token: string;
  };
  token_type: string;
  user: User;
}

export interface RefreshResponse {
  access_token: string;
  token_type: string;
}