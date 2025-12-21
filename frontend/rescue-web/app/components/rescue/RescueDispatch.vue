<script setup lang="ts">
import { ref, watch } from 'vue';
import { ElMessage } from 'element-plus';
import { Phone, VideoPlay, Location } from '@element-plus/icons-vue';
import type { RescueRequest, RescueTeam } from '@/types/rescue';

const { findNearbyTeams, assignTeam } = useRescueService();

const props = defineProps<{
    modelValue: boolean; // Trạng thái đóng/mở
    request: RescueRequest | null;
}>();

const emit = defineEmits(['update:modelValue', 'success']); // Emit success để cha reload lại data

const loading = ref(false);
const submitting = ref(false); // Loading cho nút bấm
const teams = ref<RescueTeam[]>([]);
const radius = ref(10); 

// 1. Tìm kiếm đội
const fetchTeams = async () => {
    if (!props.request) return;
    loading.value = true;
    try {
        teams.value = await findNearbyTeams({
            latitude: props.request.latitude,
            longitude: props.request.longitude,
            radius_km: radius.value
        });
    } catch (e) {
        teams.value = [];
    } finally {
        loading.value = false;
    }
};

// 2. Xử lý gán đội (Gọi API bạn vừa sửa)
const handleAssign = async (team: RescueTeam) => {
    if (!props.request) return;
    
    submitting.value = true;
    try {
        await assignTeam({
            requestId: props.request.id,
            rescueTeamId: team.id
        });
        
        ElMessage.success(`Đã điều động: ${team.name}`);
        emit('update:modelValue', false); // Đóng dialog
        emit('success'); // Báo cho cha biết để cập nhật trạng thái
    } catch (e) {
        ElMessage.error('Lỗi khi điều động đội cứu hộ');
        console.error(e);
    } finally {
        submitting.value = false;
    }
};

// Tự động tìm khi mở dialog
watch(() => props.modelValue, (val) => {
    if (val) fetchTeams();
});
</script>

<template>
    <el-dialog 
        :model-value="modelValue" 
        title="Tìm Đội Cứu Hộ Lân Cận" 
        width="650px"
        destroy-on-close
        @close="$emit('update:modelValue', false)"
    >
        <div class="space-y-4">
            <div class="flex items-center gap-4 bg-slate-50 p-3 rounded border border-slate-200">
                <span class="text-sm font-bold text-slate-600">Bán kính:</span>
                <el-slider v-model="radius" :min="1" :max="50" show-input class="flex-1" @change="fetchTeams"/>
                <span class="text-xs text-slate-500">km</span>
            </div>

            <el-table :data="teams" v-loading="loading" height="350" empty-text="Không tìm thấy đội nào">
                <el-table-column label="Đội cứu hộ" min-width="200">
                    <template #default="{ row }">
                        <div class="font-bold text-slate-800">{{ row.name }}</div>
                        <div v-if="row.contact_phone" class="text-xs text-slate-500 flex items-center gap-1">
                            <el-icon><Phone /></el-icon> {{ row.contact_phone }}
                        </div>
                    </template>
                </el-table-column>
                
                <el-table-column label="Khoảng cách" width="120" align="center" sortable prop="distance">
                    <template #default="{ row }">
                        <el-tag effect="plain" round class="font-mono">
                            {{ row.distance.toFixed(2) }} km
                        </el-tag>
                    </template>
                </el-table-column>

                <el-table-column width="100" align="right">
                    <template #default="{ row }">
                        <el-button 
                            type="primary" 
                            size="small" 
                            :icon="VideoPlay" 
                            :loading="submitting"
                            @click="handleAssign(row)"
                        >
                            Chọn
                        </el-button>
                    </template>
                </el-table-column>
            </el-table>
        </div>
    </el-dialog>
</template>