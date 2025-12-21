// stores/auth.store.ts
import { defineStore } from 'pinia';
import type { User } from '~/types/auth';

export const useAuthStore = defineStore('auth', () => {
  
  const { login: loginApi, logout: logoutApi } = useAuthService();

  const user = ref<User | null>(null);
  const cookieOptions = { path: '/' }; 
  
  const accessToken = useCookie('access_token', cookieOptions);
  const refreshToken = useCookie('refresh_token', cookieOptions);
  const loading = ref(false);

  const isAuthenticated = computed(() => !!accessToken.value);

  // LOGIN
  async function login(form: any) {
    loading.value = true;
    try {
      const data = await loginApi(form.identifier, form.password);
      accessToken.value = data.access_token;
      user.value = data.user;
      return navigateTo('/admin');
    } catch (error: any) {
      throw error;
    } finally {
      loading.value = false;
    }
  }

  // LOGOUT
  async function logout() {
    try {
      await logoutApi();
    } catch (error) {
      console.warn('Logout API warning:', error);
    } finally {
      const accessToken = useCookie('access_token');
      const refreshToken = useCookie('refresh_token');
      
      accessToken.value = null;
      refreshToken.value = null;
      user.value = null;
      
      await navigateTo('/login', { replace: true });
    }
  }

  return { user, accessToken, refreshToken, loading, isAuthenticated, login, logout };
});