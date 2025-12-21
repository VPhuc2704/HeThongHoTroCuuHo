<script setup lang="ts">
import { ref } from 'vue';
import { InfoFilled, MapLocation } from '@element-plus/icons-vue';
import type { RescueRequest } from '@/types/rescue';
import { ElMessage } from 'element-plus';

// Import 3 components con
import RescueMap from './RescueMap.vue';
import RescueInfo from './RescueInfo.vue';
import RescueTaskControl from './RescueTaskControl.vue';
import RescueDispatch from './RescueDispatch.vue';

const props = defineProps<{
    request: RescueRequest | null;
}>();

const emit = defineEmits(['refresh']);
const showDispatchDialog = ref(false);

const handleOpenDispatch = () => {
    if (!props.request) return;
    showDispatchDialog.value = true;
};

const onAssignSuccess = () => {
    ElMessage.success('Điều động thành công!');
    showDispatchDialog.value = false;
    emit('refresh'); // Báo cho cha reload list
};

const handleCancelTask = () => {
    // Gọi API hủy task ở đây...
    console.log("Hủy task");
};
</script>

<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col h-full overflow-hidden">
        
        <div class="p-4 border-b flex items-center gap-3 bg-slate-50 border-slate-100">
            <el-icon class="text-blue-600" :size="20"><InfoFilled /></el-icon>
            <h3 class="font-bold text-slate-800 text-base uppercase tracking-wide">Chi tiết Yêu cầu</h3>
            
            <template v-if="request">
                <el-tag v-if="request.active_assignment" type="success" size="small" class="ml-auto font-bold">
                    {{ request.active_assignment.status }}
                </el-tag>
                <el-tag v-else type="warning" size="small" class="ml-auto font-bold">
                    Chờ xử lý
                </el-tag>
            </template>
        </div>

        <div v-if="request" class="flex-1 flex flex-col overflow-hidden relative">
            
            <div class="h-60 shrink-0 border-b border-slate-200 relative z-0">
                <RescueMap :request="request" />
            </div>

            <div class="flex-1 overflow-y-auto custom-scrollbar">
                <RescueInfo :request="request" />
            </div>

            <RescueTaskControl 
                :request="request"
                @openDispatch="handleOpenDispatch"
                @cancelTask="handleCancelTask"
            />
        </div>

        <div v-else class="flex-1 flex flex-col items-center justify-center text-slate-400 p-8 text-center bg-slate-50/50">
            <el-icon class="text-6xl mb-4 opacity-20"><MapLocation /></el-icon>
            <p class="font-medium">Chọn một yêu cầu từ danh sách<br>để xem vị trí và chi tiết</p>
        </div>

        <RescueDispatch
            v-model="showDispatchDialog"
            :request="request"
            @success="onAssignSuccess"
        />
    </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
.custom-scrollbar::-webkit-scrollbar-thumb { background-color: #cbd5e1; border-radius: 20px; }
</style>