<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { 
    Plus, Search, Lock, Unlock, Refresh, CopyDocument, 
    Edit, Delete, Key
} from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import AccountCreate from '~/components/account/AccountCreate.vue';
 
definePageMeta({ layout: 'admin' });



// 1. Kết nối Composable
const { 
    loading, 
    accounts, 
    search,
    hasMore,
    fetchData, 
    handleSearch,
    handleLoadMore,
    handleToggleStatus
} = useAccountList();

// 2. State cục bộ
const dialogVisible = ref(false);

const copyToClipboard = (text: string | number) => {
    navigator.clipboard.writeText(String(text));
    ElMessage.success('Đã sao chép ID');
};

const formatDate = (dateString: string) => {
    if (!dateString) return 'N/A';
    // Format theo kiểu Việt Nam: 20/12/2025
    return new Date(dateString).toLocaleDateString('vi-VN', {
        day: '2-digit', 
        month: '2-digit', 
        year: 'numeric'
    });
};

const handleEdit = (row: any) => {
    console.log('Sửa:', row);

};

const handleResetPassword = (row: any) => {
    ElMessageBox.prompt('Nhập mật khẩu mới:', 'Đặt lại mật khẩu', {
        inputType: 'password',
        inputPattern: /.{6,}/,
        inputErrorMessage: 'Mật khẩu tối thiểu 6 ký tự'
    }).then(({ value }) => {
        console.log('Password mới:', value);
        ElMessage.success('Đổi mật khẩu thành công');
    });
};

const handleDelete = (row: any) => {
    console.log('Xóa:', row.id);
    ElMessage.success('Đã xóa thành công');
    // fetchData();
};

onMounted(fetchData);
</script>

<template>
    <div class="p-6 max-w-[1400px] mx-auto space-y-6">
        
        <div class="flex flex-col md:flex-row justify-between items-center gap-4">
            <div>
                <h1 class="text-2xl font-bold text-slate-800">Quản lý Tài khoản</h1>
                <p class="text-slate-500 text-sm">Quản lý người dùng & phân quyền hệ thống</p>
            </div>
            <div class="flex items-center gap-3 w-full md:w-auto">
                <el-input 
                    v-model="search" 
                    placeholder="Tìm kiếm Email / SĐT..." 
                    class="w-full md:w-64"
                    clearable
                    @clear="handleSearch"
                    @keyup.enter="handleSearch"
                >
                    <template #prefix><el-icon><Search /></el-icon></template>
                </el-input>
                <el-button :icon="Refresh" circle plain @click="fetchData(false)" />
                <el-button type="primary" :icon="Plus" class="shadow-blue-200 shadow-md" @click="dialogVisible = true">
                    Thêm Mới
                </el-button>
            </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
            <el-table 
                :data="accounts" 
                v-loading="loading" 
                style="width: 100%"
                row-class-name="hover:bg-slate-50 transition-colors"
            >
                <el-table-column label="ID" width="100" align="center">
                    <template #default="{ row }">
                        <div class="group flex items-center justify-center gap-1">
                            <el-tooltip :content="row.id" placement="top" :show-after="500">
                                <span class="text-xs font-mono text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded cursor-help">
                                    {{ row.id.slice(0, 6) }}..
                                </span>
                            </el-tooltip>
                            <el-icon class="text-slate-400 cursor-pointer hover:text-blue-500 opacity-0 group-hover:opacity-100 transition-opacity" @click="copyToClipboard(row.id)"><CopyDocument /></el-icon>
                        </div>
                    </template>
                </el-table-column>
                
                <el-table-column label="Người dùng" min-width="200">
                    <template #default="{ row }">
                        <div class="flex items-center gap-3 py-2">
                            <el-avatar :size="32" class="bg-indigo-600 text-white font-bold text-xs shrink-0">
                                {{ getAvatarLetter(row.email) }}
                            </el-avatar>
                            <div class="flex flex-col overflow-hidden">
                                <span class="font-semibold text-slate-800 text-sm truncate" :title="row.email">
                                    {{ row.email || 'Không có email' }}
                                </span>
                                <span class="text-[10px] text-slate-400">
                                    Tham gia: {{ formatDate(row.created_at) }}
                                </span>
                            </div>
                        </div>
                    </template>
                </el-table-column>

                <el-table-column label="Số điện thoại" min-width="140">
                    <template #default="{ row }">
                        <span class="text-sm text-slate-600 font-mono">
                            {{ row.phone || '-' }}
                        </span>
                    </template>
                </el-table-column>

                <el-table-column label="Vai trò" width="150">
                    <template #default="{ row }">
                        <el-tag :type="getRoleInfo(row.role?.name).type" effect="light" round class="border-0 px-2 h-7">
                            <div class="flex items-center gap-1.5 font-medium text-xs">
                                <el-icon><component :is="getRoleInfo(row.role?.name).icon" /></el-icon>
                                {{ getRoleInfo(row.role?.name).label }}
                            </div>
                        </el-tag>
                    </template>
                </el-table-column>

                <el-table-column label="Trạng thái" width="120" align="center">
                    <template #default="{ row }">
                        <div v-if="row.is_active" class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-green-50 text-green-700 border border-green-100 uppercase tracking-wide">
                            <span class="w-1.5 h-1.5 mr-1.5 bg-green-500 rounded-full animate-pulse"></span>
                            Active
                        </div>
                        <div v-else class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-50 text-red-700 border border-red-100 uppercase tracking-wide">
                            <span class="w-1.5 h-1.5 mr-1.5 bg-red-500 rounded-full"></span>
                            Locked
                        </div>
                    </template>
                </el-table-column>

                <el-table-column label="Thao tác" align="center" width="160" fixed="right">
                    <template #default="{ row }">
                        <div class="flex items-center justify-center gap-1">
                            
                            <el-tooltip content="Sửa thông tin" placement="top" :show-after="500">
                                <el-button type="primary" :icon="Edit" circle plain size="small" @click="handleEdit(row)" />
                            </el-tooltip>

                            <el-tooltip content="Đổi mật khẩu" placement="top" :show-after="500">
                                <el-button type="warning" :icon="Key" circle plain size="small" @click="handleResetPassword(row)" />
                            </el-tooltip>

                            <el-tooltip :content="row.is_active ? 'Khóa' : 'Mở khóa'" placement="top" :show-after="500">
                                <el-button 
                                    :type="row.is_active ? 'danger' : 'success'" 
                                    :icon="row.is_active ? Lock : Unlock"
                                    circle plain size="small"
                                    @click="handleToggleStatus(row)"
                                />
                            </el-tooltip>

                            <el-popconfirm title="Xóa người dùng này?" @confirm="handleDelete(row)" width="200">
                                <template #reference>
                                    <el-button type="danger" :icon="Delete" circle plain size="small" />
                                </template>
                            </el-popconfirm>

                        </div>
                    </template>
                </el-table-column>
            </el-table>

            <div class="p-4 flex justify-center bg-slate-50 border-t border-slate-100">
                <el-button 
                    v-if="hasMore" 
                    :loading="loading" 
                    @click="handleLoadMore"
                    round
                    class="px-6"
                >
                    Tải thêm dữ liệu
                </el-button>
                <span v-else-if="accounts.length > 0" class="text-xs text-slate-400 italic py-2">
                    Đã hiển thị hết danh sách
                </span>
                <span v-else class="text-sm text-slate-500 py-2">
                    Không tìm thấy dữ liệu
                </span>
            </div>
        </div>

        <AccountCreate
            v-model="dialogVisible" 
            @success="handleSearch" 
        />
    </div>
</template>