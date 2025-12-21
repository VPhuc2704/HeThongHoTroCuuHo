import type { NitroFetchOptions, NitroFetchRequest } from 'nitropack';

export const useApiClient = () => {
  const config = useRuntimeConfig();
  const accessToken = useCookie('access_token'); 

  const apiFetch = async <T>(
    url: string, 
    options: NitroFetchOptions<NitroFetchRequest> = {}
  ) => {
    const defaults: NitroFetchOptions<NitroFetchRequest> = {
      baseURL: config.public.apiBase,
      // Quan trọng: Nếu API khác domain với FE, cần bật credentials để browser tự gửi Cookie HttpOnly
      credentials: 'include',
      headers: accessToken.value 
        ? { Authorization: `Bearer ${accessToken.value}` } 
        : {},
    };

    // Merge options
    const params = { ...defaults, ...options };

    try {
      // 2. GỌI LẦN 1: Thử gọi API bình thường
      return await $fetch<T>(url, params);
    } catch (error: any) {
      // 3. XỬ LÝ KHI LỖI 401 (Hết hạn Access Token)
      if (error.response?.status === 401) {
        try {
          // Gọi API Refresh
          // Vì Refresh Token nằm trong HttpOnly Cookie, trình duyệt sẽ TỰ ĐỘNG gửi nó đi
          // Bạn không cần (và không thể) đính kèm refresh token thủ công
          const refreshResponse = await $fetch<any>('/api/auth/refresh', {
            baseURL: config.public.apiBase,
            method: 'POST', // Hoặc GET tùy BE
            credentials: 'include', // Bật nếu khác domain
          });

          // 4. LẤY ACCESS TOKEN MỚI
          // BE trả về access_token mới trong response body
          const newAccessToken = refreshResponse.access_token; 
          
          // Lưu lại vào Cookie của FE
          accessToken.value = newAccessToken;

          // 5. RETRY (GỌI LẠI) REQUEST CŨ
          // Cập nhật header với token mới
          params.headers = {
            ...params.headers,
            Authorization: `Bearer ${newAccessToken}`
          };

          // Thực hiện gọi lại request ban đầu và trả về kết quả
          return await $fetch<T>(url, params);

        } catch (refreshError) {
          // 6. TRƯỜNG HỢP XẤU NHẤT: Refresh Token cũng hết hạn hoặc lỗi
          // Logout user
          accessToken.value = null;
          navigateTo('/login');
          throw refreshError; // Ném lỗi để component biết mà dừng loading
        }
      }
      throw error;
    }
  };

  return { apiFetch };
};