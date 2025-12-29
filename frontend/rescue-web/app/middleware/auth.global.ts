// middleware/auth.global.ts
import { useAuthStore } from '~/stores/auth.store';

export default defineNuxtRouteMiddleware((to, from) => {
  const authStore = useAuthStore();
  
  const publicPages = ['/login', '/register'];
  

  if (authStore.isAuthenticated && publicPages.includes(to.path)) {
    return navigateTo('/admin');
  }

  if (!authStore.isAuthenticated && !publicPages.includes(to.path)) {
    return navigateTo('/login');
  }
});