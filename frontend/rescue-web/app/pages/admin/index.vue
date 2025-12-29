<!-- <script setup lang="ts">
import { WarningFilled, UserFilled, Finished, LocationFilled, ArrowRight } from '@element-plus/icons-vue';
import MapWidget from '~/components/MapWidget.vue';
import StatCard from '~/components/StatCard.vue';
import { useRealtimeMap } from '~/composables/useRealtimeMap';

definePageMeta({ layout: 'admin' });

const { points, socketStatus, fetchPoints } = useRealtimeMap();

const statData = [
  { title: 'Sự cố đang chờ', value: 12, unit: 'vụ', icon: WarningFilled, color: 'red' as const, change: '+15%', percent: 60 },
  { title: 'Lực lượng sẵn sàng', value: 5, unit: 'đơn vị', icon: UserFilled, color: 'green' as const, change: '-5%', percent: 50 },
  { title: 'Đã xử lý hôm nay', value: 28, unit: 'vụ', icon: Finished, color: 'blue' as const, change: '+2%', percent: 28 },
];
</script>

<template>
  <div class="p-0">
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
      <StatCard 
        v-for="(stat, idx) in statData" 
        :key="idx" 
        v-bind="stat" 
      />

      <div class="bg-slate-800 p-4 rounded-xl border border-slate-700 shadow-lg flex flex-col justify-between">
        <h3 class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2">Truy Cập Nhanh</h3>
        <NuxtLink to="/admin/incidents" class="flex items-center justify-between px-3 py-2 bg-slate-700/30 rounded-lg hover:bg-slate-700 transition-colors group">
          <span class="text-slate-300 text-sm font-medium group-hover:text-white">Sự cố đang chờ</span>
          <el-icon class="text-red-500 text-base group-hover:scale-110 transition-transform"><WarningFilled /></el-icon>
        </NuxtLink>
        <NuxtLink to="/admin/users" class="mt-1 flex items-center justify-between px-3 py-2 bg-slate-700/30 rounded-lg hover:bg-slate-700 transition-colors group">
          <span class="text-slate-300 text-sm font-medium group-hover:text-white">Quản lý Cán bộ</span>
          <el-icon class="text-blue-500 text-base group-hover:scale-110 transition-transform"><UserFilled /></el-icon>
        </NuxtLink>
      </div>
    </div>
    
    <div class="grid grid-cols-1">
      <div class="bg-slate-900 min-h-[70vh] rounded-xl shadow-2xl relative overflow-hidden flex flex-col">
        <div class="bg-slate-800 p-3 flex justify-between items-center border-b border-red-500/50">
          <h3 class="text-sm font-semibold text-white uppercase tracking-wider flex items-center gap-2">
            <el-icon class="text-red-500"><LocationFilled /></el-icon>
            Giám sát Trực tuyến
          </h3>
          <div class="flex items-center gap-3">
            <span class="text-[10px] text-slate-400 font-mono flex items-center gap-1">
              <span class="w-2 h-2 rounded-full" :class="socketStatus === 'OPEN' ? 'bg-green-500 animate-pulse' : 'bg-red-500'"></span>
              {{ socketStatus === 'OPEN' ? 'LIVE' : 'OFFLINE' }}
            </span>
            <NuxtLink to="/admin/map" class="text-xs text-blue-400 hover:text-blue-300 font-medium flex items-center gap-1">
              Xem Bản đồ Lớn <el-icon><ArrowRight /></el-icon>
            </NuxtLink>
          </div>
        </div>
        
        <div class="flex-1 relative bg-slate-800">
          <ClientOnly>
            <MapWidget 
              :points="points" 
              @fetch-new-data="fetchPoints" 
            />
            <template #fallback>
              <div class="w-full h-full flex items-center justify-center text-slate-500 animate-pulse">
                Loading Map Infrastructure...
              </div>
            </template>
          </ClientOnly>
        </div>
      </div>
    </div>
  </div>
</template> -->


<script setup lang="ts">
import { 
  WarningFilled, UserFilled, Finished, ArrowRight, Timer, View,
  Bell, ChatDotRound, CircleCheckFilled, InfoFilled, WarnTriangleFilled
} from '@element-plus/icons-vue';
import StatCard from '~/components/StatCard.vue'; // Đảm bảo bạn đã có component này

definePageMeta({ layout: 'admin' });

// --- DATA 1: THỐNG KÊ TỔNG QUAN (Stats Cards) ---
const statData = [
  { title: 'Sự cố đang chờ', value: 12, unit: 'vụ', icon: WarningFilled, color: 'red' as const, change: '+15%', percent: 60 },
  { title: 'Lực lượng sẵn sàng', value: 5, unit: 'đơn vị', icon: UserFilled, color: 'green' as const, change: '-5%', percent: 50 },
  { title: 'Đã xử lý hôm nay', value: 28, unit: 'vụ', icon: Finished, color: 'blue' as const, change: '+2%', percent: 28 },
];

// --- DATA 2: BẢNG SỰ CỐ GẦN ĐÂY (Recent Incidents Table) ---
const recentIncidents = [
  { id: 1, code: 'SC-2305', name: 'Nguyễn Văn A', phone: '0901234567', address: '123 Lê Lợi, Q1, HCM', status: 'PENDING', time: 'Vừa xong' },
  { id: 2, code: 'SC-2304', name: 'Trần Thị B', phone: '0912345678', address: 'Chung cư ABC, Q7', status: 'PROCESSING', time: '30 phút trước' },
  { id: 3, code: 'SC-2303', name: 'Lê Văn C', phone: '0987654321', address: 'Khu dân cư XYZ, Bình Chánh', status: 'PENDING', time: '45 phút trước' },
  { id: 4, code: 'SC-2302', name: 'Phạm Thị D', phone: '0999888777', address: '321 Điện Biên Phủ, BT', status: 'DONE', time: '1 giờ trước' },
  { id: 5, code: 'SC-2301', name: 'Hoàng Văn E', phone: '0909090909', address: 'Cầu Sài Gòn', status: 'CANCELLED', time: '2 giờ trước' },
];

// --- DATA 3: NHẬT KÝ HOẠT ĐỘNG (Activity Timeline Log) ---
const activityLogs = [
  { id: 1, type: 'alert', message: 'Nhận tín hiệu SOS mới từ Q.Bình Thạnh', time: 'Vừa xong', icon: Bell, color: 'text-red-500 bg-red-500/10 border-red-500/20' },
  { id: 2, type: 'info', message: 'Xe chữa cháy đội 1 đang tiếp cận hiện trường', time: '2 phút trước', icon: InfoFilled, color: 'text-blue-400 bg-blue-500/10 border-blue-500/20' },
  { id: 3, type: 'chat', message: 'Đội trưởng Nam: "Cần chi viện thêm y tế"', time: '5 phút trước', icon: ChatDotRound, color: 'text-orange-400 bg-orange-500/10 border-orange-500/20' },
  { id: 4, type: 'success', message: 'Sự cố #SC-2302 đã xử lý hoàn tất', time: '15 phút trước', icon: CircleCheckFilled, color: 'text-green-500 bg-green-500/10 border-green-500/20' },
  { id: 5, type: 'system', message: 'Hệ thống tự động sao lưu dữ liệu', time: '30 phút trước', icon: WarnTriangleFilled, color: 'text-slate-400 bg-slate-500/10 border-slate-500/20' },
];

// Helpers
const getStatusColor = (status: string) => {
    switch(status) {
        case 'PENDING': return 'text-red-400 bg-red-400/10 border-red-400/20';
        case 'PROCESSING': return 'text-blue-400 bg-blue-400/10 border-blue-400/20';
        case 'DONE': return 'text-green-400 bg-green-400/10 border-green-400/20';
        case 'CANCELLED': return 'text-slate-400 bg-slate-400/10 border-slate-400/20';
        default: return 'text-slate-400 bg-slate-400/10 border-slate-400/20';
    }
};

const getStatusText = (status: string) => {
    const map: Record<string, string> = { 'PENDING': 'Đang chờ', 'PROCESSING': 'Đang xử lý', 'DONE': 'Hoàn thành', 'CANCELLED': 'Đã hủy' };
    return map[status] || status;
}
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
          
          <div class="overflow-x-auto flex-1">
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
                    <tr v-for="item in recentIncidents" :key="item.id" class="hover:bg-slate-700/30 transition-colors group">
                        <td class="p-4 font-mono text-blue-400 font-semibold group-hover:text-blue-300">#{{ item.code }}</td>
                        <td class="p-4">
                            <div class="text-slate-200 font-medium">{{ item.name }}</div>
                            <div class="text-xs text-slate-500 truncate max-w-[200px]" :title="item.address">{{ item.address }}</div>
                        </td>
                        <td class="p-4">
                            <span class="px-2.5 py-1 rounded-md text-[10px] font-bold border uppercase tracking-wider" :class="getStatusColor(item.status)">
                                {{ getStatusText(item.status) }}
                            </span>
                        </td>
                        <td class="p-4 text-right text-slate-400 text-xs font-mono">{{ item.time }}</td>
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
/* CSS cho thanh cuộn nhỏ gọn trong Widget Log */
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
