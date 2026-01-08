// composables/useRescueTaskList.ts
import { ref, computed } from 'vue';
import type { RescueTask, RescueRequest } from '~/types/task';

export const useRescueTaskList = () => {
    const { getAssignments } = useRescueService();

    const searchQuery = ref('');
    const statusFilter = ref('');

    // Gọi API bằng useAsyncData để có SSR và state pending/refresh
    const { data: tasks, pending, refresh, error } = useAsyncData<RescueTask[]>(
        'rescue-assignments', 
        () => getAssignments(),
        {
            server: false, // Tắt chạy trên Server, chỉ chạy ở Browser
            lazy: true,    // Hiển thị loading trong khi chờ client fetch
            default: () => [] // Mặc định trả về mảng rỗng để không bị lỗi null
        }
    );

    // Logic Filter (Client-side)
    const filteredTasks = computed(() => {

        console.log('🔥 DEBUG TASKS:', tasks.value);
        console.log('🔍 Is Array?', Array.isArray(tasks.value));
        console.log('📏 Length:', tasks.value?.length);
        
        const currentTasks = tasks.value || [];

        return currentTasks.filter(task => {
            const query = searchQuery.value.toLowerCase();
            
            // Safety check
            const requestCode = task.rescue_request?.code?.toLowerCase() || '';
            const requestName = task.rescue_request?.name?.toLowerCase() || '';
            const teamName = task.rescue_team?.team_name?.toLowerCase() || '';

            const matchesSearch = 
                requestCode.includes(query) ||
                requestName.includes(query) ||
                teamName.includes(query);
            
            const matchesStatus = statusFilter.value ? task.status === statusFilter.value : true;

            return matchesSearch && matchesStatus;
        });
    });

    // --- Helper Functions ---
    const formatDateTime = (isoString: string) => {
        if (!isoString) return '';
        return new Date(isoString).toLocaleString('vi-VN', {
            hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit'
        });
    };

    const getStatusType = (status: string) => {
        // Chuẩn hóa string về lowercase để so sánh cho an toàn nếu cần
        // hoặc so sánh trực tiếp
        switch (status) {
            case 'Đã điều động':
                return 'primary'; // Blue
            
            case 'Đang di chuyển':
                return 'warning'; // Orange
            
            case 'Đã đến':
                return 'danger';  // Red (Đang ở hiện trường)
            
            case 'Hoàn thành':
                return 'success'; // Green
            
            default:
                return 'info';    // Gray
        }
    };

    const getPeopleSummary = (req: RescueRequest) => {
        if (!req) return 'N/A';
        const total = (req.adults || 0) + (req.children || 0) + (req.elderly || 0);
        return `${total} người (${req.adults}L, ${req.children}N, ${req.elderly}G)`;
    };

    return {
        // State
        tasks,
        filteredTasks,
        pending,
        error,
        searchQuery,
        statusFilter,
        
        // Actions
        refresh,
        
        // Helpers
        formatDateTime,
        getStatusType,
        getPeopleSummary
    };
};