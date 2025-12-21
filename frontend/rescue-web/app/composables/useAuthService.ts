// composables/useAuthService.ts
import type { AuthResponse } from '~/types/auth';

// 1. Đổi tên thành useAuthService
export const useAuthService = () => {
  const { apiFetch } = useApiClient();
  const accessToken = useCookie('access_token');
  const refreshToken = useCookie('refresh_token');
  const router = useRouter();
  
  const login = async (identifier: string, password: string) => {
    return await apiFetch<AuthResponse>('/api/auth/login', {
      method: 'POST',
      body: { identifier, password }
    });
  }

  const register = async (email: string, password: string) => {
    return await apiFetch('/api/auth/register', {
      method: 'POST',
      body: { email, password }
    });
  }

  const logout = async () => {
    await apiFetch('/api/auth/logout', { 
      method: 'POST',
    });
  };

  return { register, login, logout };
}