<script setup lang="ts">
import { computed } from 'vue';
import { 
  UserFilled, 
  Van, 
  Phone, 
  CircleCheckFilled, 
  CircleCloseFilled 
} from '@element-plus/icons-vue';

import type { RescueRequest } from '@/types/rescue';

const props = defineProps<{ request: RescueRequest }>();
const emit = defineEmits(['openDispatch', 'cancelTask', 'callTeam']);

const assignment = computed(() => props.request.active_assignment);

// Kiểm tra xem task đã kết thúc chưa (để ẩn nút Hủy)
const isFinished = computed(() => {
    if (!assignment.value) return false;
    const s = assignment.value.status?.toLowerCase();
    return s?.includes('hoàn thành') || s?.includes('hủy') || s?.includes('xong');
});

// Cấu hình giao diện dựa trên trạng thái
const statusConfig = computed(() => {
    if (!assignment.value) return {};
    
    const status = assignment.value.status || 'Đang thực hiện';
    
    // Trạng thái: Hoàn thành
    if (status.toLowerCase().includes('hoàn thành')) {
        return {
            colorClass: 'text-green-700 bg-green-50 border-green-200',
            iconColor: 'text-green-600',
            badgeBg: 'bg-green-100',
            icon: CircleCheckFilled,
            label: 'ĐÃ HOÀN THÀNH'
        };
    }
    
    // Trạng thái: Mặc định (Đang thực hiện/Đang di chuyển)
    return {
        colorClass: 'text-blue-700 bg-blue-50 border-blue-200',
        iconColor: 'text-blue-600',
        badgeBg: 'bg-blue-100',
        icon: Van,
        label: status.toUpperCase()
    };
});

// Format thời gian đơn giản
const formattedTime = computed(() => {
    if (!assignment.value?.updated_at) return '';
    const date = new Date(assignment.value.updated_at);
    return new Intl.DateTimeFormat('vi-VN', { 
        hour: '2-digit', 
        minute: '2-digit', 
        day: '2-digit', 
        month: '2-digit' 
    }).format(date);
});
</script>

<template>
    <div class="pt-2 mt-auto sticky bottom-0 bg-white pb-4 border-t border-slate-100 px-4 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)]">
        
        <div v-if="assignment" 
             class="border rounded-lg p-3 shadow-sm transition-all"
             :class="statusConfig.colorClass">
            
            <div class="flex items-center justify-between mb-3 border-b border-black/5 pb-2">
                <span class="text-xs font-bold uppercase flex items-center gap-1.5" :class="statusConfig.colorClass?.split(' ')[0]">
                    <el-icon :size="16"><component :is="statusConfig.icon" /></el-icon> 
                    {{ statusConfig.label }}
                </span>
                <span v-if="formattedTime" class="text-[10px] font-medium px-2 py-0.5 rounded-full" :class="statusConfig.badgeBg">
                    {{ formattedTime }}
                </span>
            </div>
            
            <div class="flex items-center gap-3 mb-3">
                <div class="bg-white p-2.5 rounded-full border shadow-sm" :class="statusConfig.colorClass?.split(' ')[2]">
                    <el-icon class="text-xl" :class="statusConfig.iconColor"><UserFilled /></el-icon>
                </div>
                <div class="flex-1 min-w-0"> <p class="font-bold text-slate-800 text-sm truncate">
                        {{ assignment.team_name || 'Đội cứu hộ chưa đặt tên' }}
                    </p>
                    <div class="flex items-center gap-1 mt-0.5">
                        <el-icon class="text-slate-400 text-xs"><Phone /></el-icon>
                        <p class="text-xs text-slate-600 font-mono font-medium">
                            {{ assignment.team_phone || 'Chưa có SĐT' }}
                        </p>
                    </div>
                </div>
            </div>

            <div class="flex gap-2">
                <a :href="`tel:${assignment.team_phone}`" class="flex-1">
                    <el-button class="w-full" size="default" type="primary" plain :icon="Phone" @click="emit('callTeam')">
                        Gọi Đội
                    </el-button>
                </a>

                <el-button 
                    v-if="!isFinished"
                    size="default" 
                    type="danger" 
                    bg 
                    text
                    class="flex-1"
                    :icon="CircleCloseFilled"
                    @click="emit('cancelTask')"
                >
                    Hủy Điều Phối
                </el-button>
            </div>
        </div>

        <el-button 
            v-else
            type="danger" 
            class="w-full h-12 text-lg font-bold shadow-lg shadow-red-100 transition-transform active:scale-95" 
            :icon="UserFilled" 
            @click="emit('openDispatch')"
        >
            ĐIỀU ĐỘNG CỨU HỘ
        </el-button>
    </div>
</template>