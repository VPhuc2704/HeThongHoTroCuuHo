<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { Edit, Location, Phone } from '@element-plus/icons-vue';
import { ElMessage } from 'element-plus';
// Đảm bảo import đúng Type đã định nghĩa (RescueTeam)
import type { Rescue } from '~/types/rescue'; 

definePageMeta({ layout: 'admin' });

// 1. Khởi tạo Service
const { getTeams, updateTeam } = useAdminService();

// 2. State
const loading = ref(false);
// Khởi tạo mảng rỗng ngay từ đầu để tránh lỗi "not iterable" khi chưa có data
const teams = ref<Rescue[]>([]); 
const editDialog = ref(false);
const submitting = ref(false);

const currentTeam = ref<Rescue>({} as Rescue);

// 3. Fetch Data
const fetchTeams = async () => {
    loading.value = true;
    try {
        // getTeams() bây giờ đã trả về mảng chuẩn [Item, Item...]
        // nhờ việc bóc tách trong Service
        teams.value = await getTeams();
    } catch (e) {
        console.error(e);
        teams.value = []; // Reset về rỗng nếu lỗi
        ElMessage.error('Không thể tải danh sách đội.');
    } finally {
        loading.value = false;
    }
};

const openEdit = (row: Rescue) => {
    // Clone object để tránh sửa trực tiếp vào bảng
    currentTeam.value = { ...row };
    editDialog.value = true;
};

const handleUpdate = async () => {
    if (!currentTeam.value.id) return;
    
    submitting.value = true;
    try {
        await updateTeam(currentTeam.value.id, {
            name: currentTeam.value.name,
            contact_phone: currentTeam.value.contact_phone,
            latitude: currentTeam.value.latitude,
            longitude: currentTeam.value.longitude,
            status: currentTeam.value.status
        });
        
        ElMessage.success('Cập nhật thành công');
        editDialog.value = false;
        fetchTeams(); // Load lại dữ liệu mới nhất
    } catch (e) {
        ElMessage.error('Lỗi cập nhật thông tin');
    } finally {
        submitting.value = false;
    }
};

onMounted(fetchTeams);
</script>

<template>
    <div class="bg-white p-4 rounded-lg shadow min-h-[500px]">
        <div class="flex justify-between mb-4">
            <h2 class="text-lg font-bold text-slate-800">Danh Sách Đội Cứu Hộ</h2>
            <el-button :icon="Edit" @click="fetchTeams" circle plain title="Tải lại" />
        </div>

        <el-table :data="teams" v-loading="loading" stripe style="width: 100%">
            
            <el-table-column label="Tên Đội" min-width="200">
                <template #default="{ row }">
                    <span class="font-bold text-blue-600">{{ row.name }}</span>
                </template>
            </el-table-column>
            
            <el-table-column label="Liên hệ" width="180">
                <template #default="{ row }">
                    <div class="flex items-center gap-2 text-slate-600">
                        <el-icon v-if="row.contact_phone"><Phone /></el-icon> 
                        {{ row.contact_phone || '---' }}
                    </div>
                </template>
            </el-table-column>

            <el-table-column label="Vị trí (Lat, Lng)" min-width="200">
                <template #default="{ row }">
                    <div v-if="row.latitude && row.longitude" class="flex items-center gap-1 text-xs font-mono bg-slate-100 p-1 px-2 rounded border border-slate-200 w-fit">
                        <el-icon class="text-red-500"><Location /></el-icon>
                        {{ Number(row.latitude).toFixed(4) }}, {{ Number(row.longitude).toFixed(4) }}
                    </div>
                    <span v-else class="text-slate-400 italic text-xs pl-2">Chưa cập nhật</span>
                </template>
            </el-table-column>

            <el-table-column label="Trạng thái" width="140" align="center">
                <template #default="{ row }">
                    <el-tag :type="row.status === 'Sẵn sàng' || row.status === 'READY' ? 'success' : 'info'" effect="light" round>
                        {{ row.status }}
                    </el-tag>
                </template>
            </el-table-column>

            <el-table-column width="100" align="right">
                <template #default="{ row }">
                    <el-button :icon="Edit" size="small" circle type="primary" plain @click="openEdit(row)" />
                </template>
            </el-table-column>
        </el-table>

        <el-dialog v-model="editDialog" title="Cập Nhật Thông Tin Đội" width="500px" destroy-on-close>
            <el-form label-position="top" class="mt-2">
                <el-form-item label="Tên đội cứu hộ">
                    <el-input v-model="currentTeam.name" placeholder="Nhập tên đội..." />
                </el-form-item>
                
                <el-form-item label="Số điện thoại liên hệ">
                    <el-input v-model="currentTeam.contact_phone" placeholder="09xxxx..." />
                </el-form-item>
                
                <div class="grid grid-cols-2 gap-4">
                    <el-form-item label="Vĩ độ (Latitude)">
                        <el-input-number v-model="currentTeam.latitude" :precision="6" :step="0.0001" class="w-full" controls-position="right" />
                    </el-form-item>
                    <el-form-item label="Kinh độ (Longitude)">
                        <el-input-number v-model="currentTeam.longitude" :precision="6" :step="0.0001" class="w-full" controls-position="right" />
                    </el-form-item>
                </div>

                <el-form-item label="Trạng thái hoạt động">
                    <el-radio-group v-model="currentTeam.status">
                        <el-radio-button label="Sẵn sàng" value="READY" />
                        <el-radio-button label="Đang bận" value="BUSY" />
                        <el-radio-button label="Nghỉ" value="OFFLINE" />
                    </el-radio-group>
                </el-form-item>
            </el-form>
            <template #footer>
                <div class="dialog-footer">
                    <el-button @click="editDialog = false">Đóng</el-button>
                    <el-button type="primary" :loading="submitting" @click="handleUpdate">Lưu thay đổi</el-button>
                </div>
            </template>
        </el-dialog>
    </div>
</template>