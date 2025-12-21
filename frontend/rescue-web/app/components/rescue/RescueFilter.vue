<script setup lang="ts">
import { Search, RefreshRight } from '@element-plus/icons-vue';

// Vue 3.4+ dùng defineModel cho gọn
const search = defineModel<string>('search');
const status = defineModel<string>('status');

const emit = defineEmits(['submit', 'reset']); // Đổi tên event 'submit' nghe hợp lý hơn
</script>

<template>
    <div class="bg-white p-4 rounded-xl shadow-sm border border-slate-200 flex items-center gap-4">
        <el-input 
            v-model="search" 
            placeholder="Tìm SĐT, Tên, Địa chỉ..." 
            class="w-72"
            @keyup.enter="$emit('submit')"
        >
            <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>

        <el-select v-model="status" placeholder="Trạng thái" class="w-48" clearable>
            <el-option label="Chờ Xử Lý" value="PENDING" />
            <el-option label="Đã phân công" value="ASSIGNED" />
            <el-option label="Đang thực hiện" value="IN_PROGRESS" />
            <el-option label="Hoàn Thành" value="COMPLETED" />
            <el-option label="An Toàn" value="SAFE" />
        </el-select>
        
        <el-button @click="$emit('submit')" type="primary">Tìm</el-button>
        <el-button @click="$emit('reset')" plain :icon="RefreshRight">Reset</el-button>
    </div>
</template>