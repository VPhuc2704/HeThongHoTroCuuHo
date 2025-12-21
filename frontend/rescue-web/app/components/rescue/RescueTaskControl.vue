<script setup lang="ts">
import { computed } from 'vue';
import { UserFilled, Van } from '@element-plus/icons-vue';
import type { RescueRequest } from '@/types/rescue';

const props = defineProps<{ request: RescueRequest }>();
const emit = defineEmits(['openDispatch', 'cancelTask', 'callTeam']);

const assignment = computed(() => props.request.active_assignment);
</script>

<template>
    <div class="pt-2 mt-auto sticky bottom-0 bg-white pb-2 border-t border-slate-100 px-4">
        
        <div v-if="assignment" class="bg-green-50 border border-green-200 rounded-lg p-3 shadow-sm">
            <div class="flex items-center justify-between mb-2">
                <span class="text-xs font-bold text-green-700 uppercase flex items-center gap-1">
                    <el-icon><Van /></el-icon> Đang thực hiện
                </span>
                <span class="text-[10px] text-green-600 bg-green-100 px-2 py-0.5 rounded-full">
                    {{ assignment.updated_at ? 'Vừa cập nhật' : '' }}
                </span>
            </div>
            
            <div class="flex items-center gap-3">
                <div class="bg-white p-2 rounded-full border border-green-100 shadow-sm">
                    <el-icon class="text-green-600 text-xl"><Van /></el-icon>
                </div>
                <div>
                    <p class="font-bold text-slate-800 text-sm">{{ assignment.team_name }}</p>
                    <p class="text-xs text-slate-500 font-mono">{{ assignment.team_phone || 'Chưa có SĐT' }}</p>
                </div>
            </div>

            <div class="flex gap-2 mt-3">
                <el-button size="small" type="primary" plain class="flex-1" @click="emit('callTeam')">Gọi điện</el-button>
                <el-button size="small" type="danger" text bg class="flex-1" @click="emit('cancelTask')">Hủy Đội</el-button>
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