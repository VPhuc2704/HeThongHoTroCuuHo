// composables/useAccountList.ts
import { ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import type { Account } from '~/types/account';

export function useAccountList() {
  // Giả sử useAdminService đã được auto-import hoặc import ở nơi khác
  const { getAccounts, toggleActive, toggleUnActive } = useAdminService();

  const loading = ref(false);
  const accounts = ref<Account[]>([]);
  const nextCursor = ref<string | null>(null); // Lưu dấu vết trang tiếp theo
  const search = ref('');

  // Biến này để check xem đã hết dữ liệu chưa (để ẩn nút Load More)
  const hasMore = ref(true);

  const fetchData = async (isLoadMore = false) => {
    loading.value = true;
    try {
      // Nếu là search mới hoặc reload -> cursor là null. 
      // Nếu là Load More -> dùng nextCursor hiện tại.
      const cursorToSend = isLoadMore ? nextCursor.value : null;

      const res = await getAccounts(cursorToSend, 10, search.value);

      if (res) {
        if (isLoadMore) {
          // Nếu là tải thêm, nối vào mảng cũ
          accounts.value = [...accounts.value, ...res.items];
        } else {
          // Nếu là tải mới, thay thế hoàn toàn
          accounts.value = res.items;
        }

        // Cập nhật cursor cho lần gọi sau
        nextCursor.value = res.next_cursor;

        // Nếu không có next_cursor -> Đã hết dữ liệu
        hasMore.value = !!res.next_cursor;
      }
    } catch (e) {
      console.error(e);
      ElMessage.error('Không thể tải danh sách');
    } finally {
      loading.value = false;
    }
  };

  const handleSearch = () => {
    // Khi search, reset lại từ đầu
    nextCursor.value = null;
    fetchData(false);
  };

  const handleLoadMore = () => {
    fetchData(true); // Flag true để biết là đang load thêm
  };

  const handleToggleStatus = async (row: any) => {
      const isCurrentlyActive = row.is_active;
      const actionName = isCurrentlyActive ? 'Khóa' : 'Kích hoạt lại';
      
      try {
          await ElMessageBox.confirm(
              `Bạn có chắc muốn <strong>${actionName}</strong> tài khoản <span class="text-blue-600">${row.email}</span>?`,
              'Xác nhận thay đổi trạng thái',
              {
                  dangerouslyUseHTMLString: true,
                  type: isCurrentlyActive ? 'warning' : 'info',
                  confirmButtonText: 'Đồng ý',
                  cancelButtonText: 'Hủy',
                  closeOnClickModal: false
              }
          );

          // GỌI API DỰA TRÊN TRẠNG THÁI HIỆN TẠI
          if (isCurrentlyActive) {
              // Đang Active -> Gọi API Lock
              // Lưu ý: row.id cần đúng kiểu dữ liệu (number/string) như Service yêu cầu
              await toggleActive(row.id, false); 
          } else {
              // Đang Locked -> Gọi API Unlock
              await toggleUnActive(row.id, true);
          }

          // Cập nhật UI ngay lập tức (Optimistic UI)
          row.is_active = !isCurrentlyActive;
          
          ElMessage.success({
              message: `Đã ${actionName} tài khoản thành công`,
              plain: true
          });

      } catch (e) {
          if (e !== 'cancel') {
              console.error(e);
              ElMessage.error('Có lỗi xảy ra, vui lòng thử lại.');
          }
      }
  };


  return {
    loading,
    accounts,
    search,
    hasMore,
    fetchData,
    handleSearch,
    handleLoadMore,
    handleToggleStatus,
  };
}