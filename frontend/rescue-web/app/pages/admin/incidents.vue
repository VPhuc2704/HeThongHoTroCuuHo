<script setup lang="ts">
import { ref, onMounted, watch } from 'vue';
import { useRescue } from '@/composables/useRescue';
import type { RescueRequest } from '@/types/rescue';

import RescueFilter from '@/components/rescue/RescueFilter.vue';
import RescueTable from '@/components/rescue/RescueTable.vue';
// import RescueDetail from '@/components/rescue/RescueDetail.vue';
import RescueDetailPanel from '~/components/rescue/RescueDetailPanel.vue';

definePageMeta({ layout: 'admin' });

const { 
    requests, loading, total, filter, 
    fetchRequests, handleSearch, handleReset 
} = useRescue();

const selectedRequest = ref<RescueRequest | null>(null);

const onSelectRequest = (row: RescueRequest) => {
    selectedRequest.value = row;
};

watch(requests, (newRequests) => {
    if (newRequests && newRequests.length > 0 && !selectedRequest.value) {
        selectedRequest.value = newRequests[0]!;
    }
});

onMounted(() => {
    fetchRequests();
});
</script>

<template>
  <div class="h-[calc(100vh-6rem)] flex flex-col space-y-4 p-4">
    
    <div class="bg-white p-4 rounded-xl shadow-sm border border-slate-100 flex-shrink-0">
        <span class="text-xs uppercase text-slate-500 font-bold tracking-wider">Tổng Sự Cố</span>
        <div class="text-3xl font-extrabold text-slate-800">{{ total }}</div>
    </div>

    <div class="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-4 overflow-hidden min-h-0">
        
        <div class="lg:col-span-8 flex flex-col h-full space-y-4 overflow-hidden">
            
            <div class="flex-shrink-0">
                <RescueFilter 
                    v-model:search="filter.search"
                    v-model:status="filter.status"
                    @submit="handleSearch"
                    @reset="handleReset"
                />
            </div>

            <div class="flex-1 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden relative">
                <div class="flex-1 overflow-hidden">
                    <RescueTable 
                        :data="requests"
                        :loading="loading"
                        @select="onSelectRequest"
                    />
                </div>
                
                <div class="p-3 border-t bg-slate-50 flex justify-end flex-shrink-0">
                    <el-pagination
                        v-model:current-page="filter.page"
                        v-model:page-size="filter.page_size"
                        :total="total"
                        :page-sizes="[10, 20, 50]"
                        layout="total, sizes, prev, pager, next"
                        background
                    />
                </div>
            </div>
        </div>

        <div class="lg:col-span-4 h-full overflow-hidden">
            <RescueDetailPanel :request="selectedRequest" />
        </div>
        
    </div>
  </div>
</template>