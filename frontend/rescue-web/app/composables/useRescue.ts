// composables/useRescue.ts
import { ref, watch } from 'vue';
import type { RescueRequest, RescueFilter } from '~/types/rescue';
import { ElMessage } from 'element-plus';

export const useRescue = () => {
    // 1. Gọi Service API
    const { getAll } = useRescueService();

    // 2. State
    const loading = ref(false);
    const requests = ref<RescueRequest[]>([]);
    const total = ref(0);
    
    // Filter State
    const filter = ref<RescueFilter>({
        page: 1,
        page_size: 20,
        search: '',
        status: 'PENDING'
    });

    // 3. Actions
    const fetchRequests = async () => {
        loading.value = true;
        try {
            // Gọi hàm getAll từ service (đã có Auth token tự động)
            const data = await getAll(filter.value);
            
            requests.value = data.items;
            total.value = data.total;
        } catch (error: any) {
            console.error(error);
            // Có thể bỏ qua ElMessage nếu muốn UI tự xử lý, hoặc giữ lại tùy UX
            ElMessage.error('Lỗi tải dữ liệu: ' + (error.message || 'Unknown'));
        } finally {
            loading.value = false;
        }
    };

    // 4. Watchers & Handlers
    
    // Debounce search nếu cần (Optional)
    let searchTimer: NodeJS.Timeout;
    const handleSearch = () => {
        clearTimeout(searchTimer);
        searchTimer = setTimeout(() => {
            filter.value.page = 1; 
            fetchRequests();
        }, 300); // Đợi 300ms sau khi gõ phím mới tìm
    };

    const handleReset = () => {
        filter.value.search = '';
        filter.value.status = '';
        filter.value.page = 1;
        fetchRequests();
    };

    // Watch deep các thay đổi khác để tự load lại (Trừ search vì đã có hàm riêng)
    watch(
        () => [filter.value.page, filter.value.page_size, filter.value.status],
        () => fetchRequests()
    );

    // Initial Fetch (Tùy chọn: có thể gọi ở onMounted trong component)
    // fetchRequests(); 

    return {
        loading,
        requests,
        total,
        filter,
        fetchRequests,
        handleSearch,
        handleReset
    };
};