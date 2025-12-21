// composables/useReportRepository.ts
import type { IRescueRequest } from '../types/report'

export const useReportRepository = () => {
  return {
    // Hàm gửi báo cáo cứu hộ
    async createReport(data: IRescueRequest) {
      // Giả lập gọi API (Sau này thay bằng đường dẫn thật)
      return new Promise((resolve) => {
        setTimeout(() => {
          console.log('Đã gửi dữ liệu lên Server:', data)
          resolve({ success: true, id: 'REPORT_123' })
        }, 1000)
      })
      
      // Code thật sẽ là:
      // return $api('/reports', { method: 'POST', body: data })
    }
  }
}