<script setup lang="ts">
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
</template>