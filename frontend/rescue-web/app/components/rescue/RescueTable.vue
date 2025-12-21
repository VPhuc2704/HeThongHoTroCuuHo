<script setup lang="ts">
import type { RescueRequest } from '@/types/rescue';
import dayjs from 'dayjs';

defineProps<{
    data: RescueRequest[];
    loading: boolean;
}>();

defineEmits<{
    (e: 'select', row: RescueRequest): void
}>();

// Helper functions
const formatDate = (date: string) => dayjs(date).format('HH:mm DD/MM/YYYY');

const getStatusType = (status: string) => {
    // Logic map màu sắc dựa trên key từ Backend
    if (status === 'PENDING') return 'danger';
    if (status === 'IN_PROGRESS') return 'warning';
    if (status === 'COMPLETED') return 'success';
    return 'info';
};
</script>

<template>
    <el-table 
        v-loading="loading"
        :data="data" 
        style="width: 100%" 
        height="100%" 
        highlight-current-row
        @row-click="(row) => $emit('select', row)"
    >
        <el-table-column label="Thời gian" width="140">
            <template #default="{ row }">
                <span class="text-xs text-slate-600">{{ formatDate(row.created_at) }}</span>
            </template>
        </el-table-column>

        <el-table-column label="Người Yêu Cầu" min-width="180">
            <template #default="{ row }">
                <div class="flex flex-col">
                    <span class="font-bold text-slate-800">{{ row.name }}</span>
                    <span class="text-xs text-slate-500">{{ row.contact_phone }}</span>
                </div>
            </template>
        </el-table-column>

        <el-table-column prop="people_summary" label="Nạn Nhân" width="150">
            <template #default="{ row }">
                <el-tag effect="plain" round>{{ row.people_summary }}</el-tag>
            </template>
        </el-table-column>

        <el-table-column label="Nhu cầu" min-width="180">
            <template #default="{ row }">
                <div class="flex flex-wrap gap-1">
                    <el-tag 
                        v-for="(c, i) in row.conditions" :key="i" 
                        size="small" type="danger" effect="light"
                    >
                        {{ c }}
                    </el-tag>
                </div>
            </template>
        </el-table-column>

        <el-table-column prop="address" label="Địa Chỉ" show-overflow-tooltip />

        <el-table-column label="Trạng Thái" width="120" align="center">
            <template #default="{ row }">
                <el-tag :type="getStatusType(row.status)" size="small">
                    {{ row.status }}
                </el-tag>
            </template>
        </el-table-column>
    </el-table>
</template>

<style scoped>
/* CSS Override để highlight dòng đang chọn rõ hơn giống file cũ */
:deep(.el-table__body tr.current-row > td.el-table__cell) {
    background-color: #e6f7ff !important;
}
</style>