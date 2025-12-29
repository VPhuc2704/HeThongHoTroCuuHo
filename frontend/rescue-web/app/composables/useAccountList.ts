// composables/useAccountList.ts
import { ref } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import type { Account } from '~/types/account';

export function useAccountList() {
  // Giả sử useAdminService đã được auto-import hoặc import ở nơi khác
  const { getAccounts, toggleActive } = useAdminService();

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

  const handleToggleStatus = async (row: Account) => {
    const action = row.is_active ? 'Khóa' : 'Kích hoạt lại';
    try {
      await ElMessageBox.confirm(
        `Bạn có chắc muốn <strong>${action}</strong> tài khoản <span class="text-blue-600">${row.email}</span>?`,
        'Xác nhận',
        {
          dangerouslyUseHTMLString: true,
          type: row.is_active ? 'warning' : 'info',
          confirmButtonText: 'Đồng ý',
          cancelButtonText: 'Hủy'
        }
      );

      // Gọi service
      await toggleActive(row.id, !row.is_active);

      // Cập nhật UI ngay lập tức (Optimistic UI)
      row.is_active = !row.is_active;
      ElMessage.success(`Đã ${action} thành công`);
    } catch (e) {
      // User hủy hoặc lỗi API thì không làm gì hoặc log lỗi
      if (e !== 'cancel') {
        console.error(e);
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
    handleToggleStatus
  };
}