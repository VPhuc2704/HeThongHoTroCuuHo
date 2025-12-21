import type { NitroFetchRequest, NitroFetchOptions } from 'nitropack'

// Hàm fetch wrapper để tự động gắn Token hoặc xử lý lỗi chung
export function $api<T>(
  request: NitroFetchRequest,
  opts?: NitroFetchOptions<NitroFetchRequest>
) {
  return $fetch<T>(request, {
    baseURL: 'https://api.mock-rescue.com/v1', // Thay bằng API thật sau này
    ...opts,
    async onResponseError({ response }) {
      // Xử lý lỗi toàn cục (VD: 401 Unauthorized -> Logout)
      console.error('API Error:', response.status)
    }
  })
}