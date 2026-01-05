<script setup lang="ts">
import { 
  Search, Filter, View, Refresh,
  UserFilled, PhoneFilled, LocationFilled, Van
} from '@element-plus/icons-vue';
import type { RescueTask } from '~/types/task';

definePageMeta({ layout: 'admin' });

// SỬ DỤNG COMPOSABLE
const { 
  filteredTasks, pending, error, refresh,
  searchQuery, statusFilter,
  formatDateTime, getStatusType, getPeopleSummary
} = useRescueTaskList();

// Các hàm xử lý sự kiện UI thuần túy
const handleRefresh = () => refresh();

const handleViewMap = (task: RescueTask) => {
  console.log("View Map ID:", task.id);
};
</script>

<template>
  <div class="h-full flex flex-col">
    
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4 flex-shrink-0">
      <div>
        <h1 class="text-2xl font-bold text-slate-800">Quản lý nhiệm vụ cứu hộ</h1>
        <p class="text-slate-500 text-sm mt-1">
          <span v-if="pending">Đang tải dữ liệu...</span>
          <span v-else>Tổng cộng: {{ filteredTasks.length }} nhiệm vụ</span>
        </p>
      </div>
      <div class="flex gap-2 w-full md:w-auto">
        <el-button :loading="pending" :icon="Refresh" @click="handleRefresh">Làm mới</el-button>
        <el-button type="primary" :icon="Filter">Xuất Excel</el-button>
      </div>
    </div>

    <el-alert
      v-if="error"
      title="Lỗi tải dữ liệu"
      type="error"
      :description="error.message"
      show-icon
      class="mb-4 flex-shrink-0"
    />

    <div class="bg-white p-4 rounded-lg shadow-sm mb-6 flex flex-wrap gap-4 items-center border border-slate-100 flex-shrink-0">
      <div class="w-full md:w-64">
        <el-input 
          v-model="searchQuery" 
          placeholder="Tìm mã, tên nạn nhân..." 
          :prefix-icon="Search"
          clearable
        />
      </div>
      
      <div class="w-full md:w-48">
        <el-select v-model="statusFilter" placeholder="Tất cả trạng thái" clearable>
          <el-option label="Đã điều động" value="Đã điều động" />
          <el-option label="Đang di chuyển" value="Đang di chuyển" />
          <el-option label="Đã đến" value="Đã đến" />
          <el-option label="Hoàn thành" value="Hoàn thành" />
        </el-select>
      </div>
    </div>

    <el-card shadow="never" class="border-none !rounded-lg w-full flex-grow flex flex-col" body-class="!p-0 h-full flex flex-col" v-loading="pending">
      <div class="w-full flex-grow" style="min-height: 500px;">
        <el-table 
          :data="filteredTasks" 
          style="width: 100%; height: 100%;" 
          stripe
          empty-text="Không có nhiệm vụ nào"
          table-layout="fixed"
        >
          <el-table-column label="Mã HS & Thời gian" min-width="160">
            <template #default="{ row }">
              <div class="flex flex-col">
                <span class="font-bold text-blue-600 hover:text-blue-800 cursor-pointer truncate">
                  {{ row.rescue_request?.code || 'N/A' }}
                </span>
                <span class="text-xs text-slate-500 mt-1">
                  {{ formatDateTime(row.assigned_at) }}
                </span>
              </div>
            </template>
          </el-table-column>

          <el-table-column label="Nạn nhân & Vị trí" min-width="240">
            <template #default="{ row }">
              <div class="space-y-1 py-1">
                <div class="flex items-center gap-1 font-medium text-slate-800">
                  <el-icon class="text-slate-400"><UserFilled /></el-icon> 
                  <span class="truncate">{{ row.rescue_request?.name }}</span>
                </div>
                <div class="flex items-center gap-1 text-xs text-slate-600">
                  <el-icon class="text-slate-400"><PhoneFilled /></el-icon> 
                  <span>{{ row.rescue_request?.contact_phone }}</span>
                </div>
                <div class="flex items-start gap-1 text-xs text-slate-500">
                   <el-icon class="text-slate-400 mt-0.5"><LocationFilled /></el-icon> 
                   <span class="truncate line-clamp-2" :title="row.rescue_request?.address">
                     {{ row.rescue_request?.address }}
                   </span>
                </div>
                <div class="mt-1">
                  <el-tag size="small" type="warning" effect="plain" class="text-[10px]">
                    {{ getPeopleSummary(row.rescue_request) }}
                  </el-tag>
                </div>
              </div>
            </template>
          </el-table-column>

          <el-table-column label="Đội thực hiện" min-width="200">
            <template #default="{ row }">
              <div class="flex items-center gap-3">
                <div class="bg-blue-50 p-2 rounded-full flex-shrink-0">
                  <el-icon class="text-blue-600"><Van /></el-icon>
                </div>
                <div class="min-w-0">
                  <p class="text-sm font-semibold text-slate-700 truncate">
                    {{ row.rescue_team?.team_name }}
                  </p>
                  <a v-if="row.rescue_team?.team_phone" :href="`tel:${row.rescue_team.team_phone}`" class="text-xs text-blue-500 hover:underline flex items-center gap-1">
                    <el-icon><PhoneFilled /></el-icon> {{ row.rescue_team.team_phone }}
                  </a>
                </div>
              </div>
            </template>
          </el-table-column>

          <el-table-column label="Trạng thái" width="140" align="center">
            <template #default="{ row }">
              <el-tag :type="getStatusType(row.status)" effect="light" class="font-bold border rounded-full px-3">
                {{ row.status }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column label="Thao tác" width="100" align="right" fixed="right">
            <template #default="{ row }">
              <el-tooltip content="Xem chi tiết" placement="top">
                <el-button circle size="small" type="info" plain :icon="View" @click="handleViewMap(row)" />
              </el-tooltip>
            </template>
          </el-table-column>

        </el-table>
      </div>

      <div class="flex justify-end p-4 border-t border-slate-100 flex-shrink-0 bg-white">
        <el-pagination layout="prev, pager, next" :total="filteredTasks.length" :page-size="20" background small />
      </div>
    </el-card>
  </div>
</template>