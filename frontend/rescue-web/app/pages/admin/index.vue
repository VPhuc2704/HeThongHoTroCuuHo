<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { 
  WarningFilled, UserFilled, Finished, ArrowRight, Timer, View,
  Bell, ChatDotRound, CircleCheckFilled, InfoFilled, WarnTriangleFilled,
  Loading
} from '@element-plus/icons-vue';
import StatCard from '~/components/StatCard.vue';
import { useRescueService } from '~/composables/useRescueService';

definePageMeta({ layout: 'admin' });

// --- 1. CONFIG & SERVICE ---
const { getAll } = useRescueService();
const isLoading = ref(false);

// Interface cho dữ liệu hiển thị trên UI
interface IncidentUI {
  id: string;
  code: string;
  name: string;
  phone: string;
  address: string;
  status: string;
  time: string; // Hiển thị dạng "Vừa xong"
}

// --- 2. STATE ---
const recentIncidents = ref<IncidentUI[]>([]);

// --- 3. MOCK DATA (Giữ nguyên cho các phần chưa có API) ---
const statData = [
  { title: 'Sự cố đang chờ', value: 12, unit: 'vụ', icon: WarningFilled, color: 'red' as const, change: '+15%', percent: 60 },
  { title: 'Lực lượng sẵn sàng', value: 5, unit: 'đơn vị', icon: UserFilled, color: 'green' as const, change: '-5%', percent: 50 },
  { title: 'Đã xử lý hôm nay', value: 28, unit: 'vụ', icon: Finished, color: 'blue' as const, change: '+2%', percent: 28 },
];

const activityLogs = [
  { id: 1, type: 'alert', message: 'Nhận tín hiệu SOS mới từ Q.Bình Thạnh', time: 'Vừa xong', icon: Bell, color: 'text-red-500 bg-red-500/10 border-red-500/20' },
  { id: 2, type: 'info', message: 'Xe chữa cháy đội 1 đang tiếp cận hiện trường', time: '2 phút trước', icon: InfoFilled, color: 'text-blue-400 bg-blue-500/10 border-blue-500/20' },
  { id: 3, type: 'chat', message: 'Đội trưởng Nam: "Cần chi viện thêm y tế"', time: '5 phút trước', icon: ChatDotRound, color: 'text-orange-400 bg-orange-500/10 border-orange-500/20' },
  { id: 4, type: 'success', message: 'Sự cố #SC-2302 đã xử lý hoàn tất', time: '15 phút trước', icon: CircleCheckFilled, color: 'text-green-500 bg-green-500/10 border-green-500/20' },
  { id: 5, type: 'system', message: 'Hệ thống tự động sao lưu dữ liệu', time: '30 phút trước', icon: WarnTriangleFilled, color: 'text-slate-400 bg-slate-500/10 border-slate-500/20' },
];

// --- 4. HELPERS ---

// Hàm tính thời gian tương đối
const timeAgo = (dateString: string | undefined) => {
  if (!dateString) return 'N/A';
  const now = new Date();
  const past = new Date(dateString);
  const diffInSeconds = Math.floor((now.getTime() - past.getTime()) / 1000);

  if (diffInSeconds < 60) return 'Vừa xong';
  if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)} phút trước`;
  if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)} giờ trước`;
  return `${Math.floor(diffInSeconds / 86400)} ngày trước`;
};

// Hàm lấy màu theo trạng thái
const getStatusColor = (status: string) => {
    switch(status) {
        case 'Chờ xử lý': return 'text-red-400 bg-red-400/10 border-red-400/20';
        case 'Đang thực hiện': return 'text-blue-400 bg-blue-400/10 border-blue-400/20';
        case 'Hoàn thành': return 'text-green-400 bg-green-400/10 border-green-400/20';
        case 'Đã phân công': return 'text-slate-400 bg-slate-400/10 border-slate-400/20';
        default: return 'text-slate-400 bg-slate-400/10 border-slate-400/20';
    }
};

// Hàm lấy text hiển thị theo trạng thái
const getStatusText = (status: string) => {
    const map: Record<string, string> = { 
      'PENDING': 'Đang chờ', 
      'PROCESSING': 'Đang xử lý', 
      'DONE': 'Hoàn thành', 
      'CANCELLED': 'Đã hủy' 
    };
    return map[status] || status;
}

// --- 5. DATA FETCHING ---
const fetchRecentIncidents = async () => {
  isLoading.value = true;
  try {
    // Gọi API lấy dữ liệu thực tế
    // Lưu ý: Đảm bảo backend trả về danh sách có các trường tương ứng hoặc chỉnh sửa map() bên dưới
    const response = await getAll({page: 1, page_size: 10 }); 
    
    const rawData = Array.isArray(response) ? response : (response as any).items || [];

    recentIncidents.value = rawData.slice(0, 10).map((item: any) => ({
      id: item.id,
      code: item.code,
      name: item.name || 'Không rõ',
      phone: item.reporter_phone || '',
      address: item.address || 'Chưa có định vị',
      status: item.status || 'PENDING',
      time: timeAgo(item.created_at)
    }));

  } catch (error) {
    console.error('Lỗi khi tải danh sách sự cố:', error);
  } finally {
    isLoading.value = false;
  }
};

// Gọi API khi component được mount
onMounted(() => {
  fetchRecentIncidents();
});
</script>

<template>
  <div class="p-0">
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <StatCard v-for="(stat, idx) in statData" :key="idx" v-bind="stat" />

      <div class="bg-slate-800 p-4 rounded-xl border border-slate-700 shadow-lg flex flex-col justify-between">
        <h3 class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2">Truy Cập Nhanh</h3>
        <NuxtLink to="/admin/incidents" class="flex items-center justify-between px-3 py-2 bg-slate-700/30 rounded-lg hover:bg-slate-700 transition-colors group">
          <span class="text-slate-300 text-sm font-medium group-hover:text-white">Danh sách sự cố</span>
          <el-icon class="text-red-500 text-base group-hover:scale-110 transition-transform"><WarningFilled /></el-icon>
        </NuxtLink>
        <NuxtLink to="/admin/map" class="mt-1 flex items-center justify-between px-3 py-2 bg-slate-700/30 rounded-lg hover:bg-slate-700 transition-colors group">
          <span class="text-slate-300 text-sm font-medium group-hover:text-white">Bản đồ trực chiến</span>
          <el-icon class="text-green-500 text-base group-hover:scale-110 transition-transform"><View /></el-icon>
        </NuxtLink>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      
      <div class="lg:col-span-2 flex flex-col">
        <div class="bg-slate-800 rounded-xl border border-slate-700 shadow-lg h-full overflow-hidden flex flex-col">
          <div class="p-4 border-b border-slate-700 flex justify-between items-center bg-slate-800/50">
             <h3 class="text-sm font-semibold text-white uppercase flex items-center gap-2">
               <el-icon class="text-red-500"><Timer /></el-icon> Tiếp nhận gần đây
             </h3>
             <NuxtLink to="/admin/incidents" class="text-xs text-blue-400 hover:underline flex items-center gap-1">
               Xem tất cả <el-icon><ArrowRight /></el-icon>
             </NuxtLink>
          </div>
          
          <div class="overflow-x-auto flex-1 relative min-h-[300px]">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="text-slate-400 text-xs border-b border-slate-700 bg-slate-900/30">
                        <th class="p-4 font-medium uppercase whitespace-nowrap">Mã SC</th>
                        <th class="p-4 font-medium uppercase whitespace-nowrap">Thông tin báo tin</th>
                        <th class="p-4 font-medium uppercase whitespace-nowrap">Trạng thái</th>
                        <th class="p-4 font-medium uppercase whitespace-nowrap text-right">Thời gian</th>
                    </tr>
                </thead>
                <tbody class="text-sm divide-y divide-slate-700/50">
                    
                    <tr v-if="isLoading">
                        <td colspan="4" class="p-10 text-center">
                            <div class="flex flex-col items-center justify-center text-slate-500 gap-2">
                                <el-icon class="is-loading text-2xl text-blue-500"><Loading /></el-icon>
                                <span class="text-xs animate-pulse">Đang cập nhật dữ liệu...</span>
                            </div>
                        </td>
                    </tr>

                    <tr v-else-if="!isLoading && recentIncidents.length === 0">
                        <td colspan="4" class="p-10 text-center text-slate-500 text-xs">
                            <div class="flex flex-col items-center gap-2">
                                <el-icon class="text-2xl"><InfoFilled /></el-icon>
                                Chưa có yêu cầu cứu hộ nào gần đây.
                            </div>
                        </td>
                    </tr>

                    <tr v-else v-for="item in recentIncidents" :key="item.id" class="hover:bg-slate-700/30 transition-colors group">
                        <td class="p-4 font-mono text-blue-400 font-semibold group-hover:text-blue-300 whitespace-nowrap">
                            #{{ item.code }}
                        </td>
                        <td class="p-4">
                            <div class="text-slate-200 font-medium">{{ item.name }}</div>
                            <div class="text-xs text-slate-500 truncate max-w-[200px]" :title="item.address">
                                {{ item.address }}
                            </div>
                            <div v-if="item.phone" class="text-[10px] text-slate-600 font-mono mt-0.5">
                                {{ item.phone }}
                            </div>
                        </td>
                        <td class="p-4">
                            <span class="px-2.5 py-1 rounded-md text-[10px] font-bold border uppercase tracking-wider whitespace-nowrap" 
                                  :class="getStatusColor(item.status)">
                                {{ getStatusText(item.status) }}
                            </span>
                        </td>
                        <td class="p-4 text-right text-slate-400 text-xs font-mono whitespace-nowrap">
                            {{ item.time }}
                        </td>
                    </tr>
                </tbody>
            </table>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-6">
        
        <div class="bg-slate-800 rounded-xl border border-slate-700 shadow-lg flex flex-col h-[400px]">
          <div class="p-4 border-b border-slate-700 bg-slate-800/50 flex justify-between items-center">
             <h3 class="text-xs font-semibold text-slate-400 uppercase flex items-center gap-2">
               <span class="relative flex h-2 w-2">
                  <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                  <span class="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                </span>
               Hoạt động trực tuyến
             </h3>
             <span class="text-[10px] text-slate-500 bg-slate-900 px-2 py-0.5 rounded border border-slate-700">Live Log</span>
          </div>

          <div class="flex-1 overflow-y-auto p-4 scrollbar-thin">
             <div class="relative border-l border-slate-700 ml-2 space-y-6 pb-2">
                <div v-for="log in activityLogs" :key="log.id" class="ml-6 relative group">
                   <span class="absolute -left-[35px] flex h-8 w-8 items-center justify-center rounded-full border ring-4 ring-slate-800 transition-transform group-hover:scale-110"
                         :class="log.color">
                      <el-icon :size="14"><component :is="log.icon" /></el-icon>
                   </span>

                   <div class="flex flex-col bg-slate-700/20 p-2 rounded-lg hover:bg-slate-700/40 transition-colors border border-transparent hover:border-slate-600">
                      <span class="text-xs font-medium text-slate-200 leading-snug">{{ log.message }}</span>
                      <span class="text-[10px] text-slate-500 mt-1 font-mono flex items-center gap-1">
                        <el-icon><Timer /></el-icon> {{ log.time }}
                      </span>
                   </div>
                </div>
             </div>
          </div>
        </div>

        <div class="bg-slate-800 rounded-xl border border-slate-700 shadow-lg p-4">
          <h3 class="text-xs font-semibold text-slate-400 uppercase mb-4 flex items-center gap-2">
            <el-icon><InfoFilled /></el-icon> Phân loại hôm nay
          </h3>
          <div class="space-y-4">
            <div>
              <div class="flex justify-between text-xs mb-1.5">
                <span class="text-slate-300 font-medium">Tai nạn giao thông</span>
                <span class="text-slate-400 font-mono">65%</span>
              </div>
              <div class="h-1.5 w-full bg-slate-900 rounded-full overflow-hidden border border-slate-700/50">
                <div class="h-full bg-gradient-to-r from-red-600 to-red-500 w-[65%] shadow-[0_0_10px_rgba(239,68,68,0.5)]"></div>
              </div>
            </div>
            <div>
              <div class="flex justify-between text-xs mb-1.5">
                <span class="text-slate-300 font-medium">Cháy nổ / Hỏa hoạn</span>
                <span class="text-slate-400 font-mono">20%</span>
              </div>
              <div class="h-1.5 w-full bg-slate-900 rounded-full overflow-hidden border border-slate-700/50">
                <div class="h-full bg-gradient-to-r from-orange-600 to-orange-500 w-[20%]"></div>
              </div>
            </div>
             <div>
              <div class="flex justify-between text-xs mb-1.5">
                <span class="text-slate-300 font-medium">Cấp cứu y tế</span>
                <span class="text-slate-400 font-mono">15%</span>
              </div>
              <div class="h-1.5 w-full bg-slate-900 rounded-full overflow-hidden border border-slate-700/50">
                <div class="h-full bg-gradient-to-r from-blue-600 to-blue-500 w-[15%]"></div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<style scoped>
/* CSS cho thanh cuộn nhỏ gọn */
.scrollbar-thin::-webkit-scrollbar {
  width: 4px;
}
.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}
.scrollbar-thin::-webkit-scrollbar-thumb {
  background-color: #475569;
  border-radius: 20px;
}
.scrollbar-thin::-webkit-scrollbar-thumb:hover {
    background-color: #64748b;
}
</style>