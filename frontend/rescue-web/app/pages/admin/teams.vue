<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue';
import { Edit, Location, Phone, User, MapLocation, House, Refresh } from '@element-plus/icons-vue';
import { ElMessage, type FormInstance, type FormRules } from 'element-plus';
import type { Rescue } from '~/types/rescue';

definePageMeta({ layout: 'admin' });

// --- 1. CONFIG & CONSTANTS ---
// Danh sách loại đội theo Constraint Database
const TEAM_TYPES = [
    { label: 'CỨU HỎA', value: 'CỨU HỎA', color: 'danger' },
    { label: 'Y TẾ', value: 'Y TẾ', color: 'success' },
    { label: 'CÔNG AN', value: 'CÔNG AN', color: 'warning' },
    { label: 'CỨU HỘ', value: 'CỨU HỘ', color: 'primary' }
];

// Danh sách trạng thái (Giả định mapping với Backend)
const TEAM_STATUS = [
    { label: 'Sẵn sàng', value: 'AVAILABLE', color: 'success' },
    { label: 'Đang bận', value: 'BUSY', color: 'danger' },
];

// --- 2. SERVICE & STATE ---
const { getTeams, updateTeam } = useAdminService();
const loading = ref(false);
const submitting = ref(false);
const teams = ref<Rescue[]>([]);
const editDialog = ref(false);

// Form Reference để validate
const formRef = ref<FormInstance>();

// Dữ liệu đang chỉnh sửa
const currentTeam = ref<Rescue>({} as Rescue);

// Rules validate
const rules = reactive<FormRules>({
    name: [{ required: true, message: 'Vui lòng nhập tên đội', trigger: 'blur' }],
    team_type: [{ required: true, message: 'Vui lòng chọn loại đội', trigger: 'change' }],
    contact_phone: [{ required: true, message: 'Nhập SĐT liên hệ', trigger: 'blur' }],
    leader_name: [{ required: true, message: 'Nhập tên đội trưởng', trigger: 'blur' }],
    latitude: [{ required: true, message: 'Nhập vĩ độ', trigger: 'blur' }],
    longitude: [{ required: true, message: 'Nhập kinh độ', trigger: 'blur' }],
});

// --- 3. METHODS ---
const fetchTeams = async () => {
    loading.value = true;
    try {
        teams.value = await getTeams();
    } catch (e) {
        console.error(e);
        ElMessage.error('Không thể tải danh sách đội.');
    } finally {
        loading.value = false;
    }
};

const openEdit = (row: Rescue) => {
    currentTeam.value = { ...row }; 
    editDialog.value = true;
    setTimeout(() => formRef.value?.clearValidate(), 0);
};

const handleUpdate = async (formEl: FormInstance | undefined) => {
    if (!formEl) return;
    
    // 1. Validate Form
    await formEl.validate(async (valid) => {
        if (valid && currentTeam.value.id) {
            submitting.value = true;
            try {
                // 2. Chuẩn bị payload (Chỉ gửi các trường cần update)
                const payload = {
                    name: currentTeam.value.name,
                    contact_phone: currentTeam.value.contact_phone,
                    leader_name: currentTeam.value.leader_name,
                    hotline: currentTeam.value.hotline,
                    team_type: currentTeam.value.team_type,
                    latitude: Number(currentTeam.value.latitude), // Đảm bảo là số
                    longitude: Number(currentTeam.value.longitude),
                    address: currentTeam.value.address,
                    primary_area: currentTeam.value.primary_area,
                    status: currentTeam.value.status,
                };

                // 3. Gọi API
                await updateTeam(currentTeam.value.id, payload);
                
                ElMessage.success('Cập nhật thông tin thành công!');
                editDialog.value = false;
                fetchTeams(); // Reload data
            } catch (e) {
                ElMessage.error('Lỗi cập nhật: ' + (e as any).message);
            } finally {
                submitting.value = false;
            }
        }
    });
};

const getTeamTypeColor = (type: string): 'danger' | 'success' | 'warning' | 'primary' | 'info' => {
    const found = TEAM_TYPES.find(t => t.value === type);
    return found ? (found.color as 'danger' | 'success' | 'warning' | 'primary' | 'info') : 'info';
};

const getStatusColor = (status: string): 'danger' | 'success' | 'warning' | 'primary' | 'info' => {
    const found = TEAM_STATUS.find(s => s.value === status);
    return found ? (found.color as 'danger' | 'success' | 'warning' | 'primary' | 'info') : 'info';
};

// Format ngày tháng
const formatDate = (dateString: string) => {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString('vi-VN');
};

onMounted(fetchTeams);
</script>

<template>
    <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-100 min-h-[600px]">
        <div class="flex justify-between items-center mb-6">
            <div>
                <h2 class="text-xl font-bold text-slate-800">Quản Lý Đội Cứu Hộ</h2>
                <p class="text-slate-500 text-sm mt-1">Danh sách và cập nhật trạng thái các đơn vị</p>
            </div>
            <el-button type="primary" plain :icon="Refresh" @click="fetchTeams">Làm mới</el-button>
        </div>

        <el-table :data="teams" v-loading="loading" stripe highlight-current-row style="width: 100%" class="custom-table">
            
            <el-table-column label="Đơn vị / Loại hình" min-width="220">
                <template #default="{ row }">
                    <div class="flex flex-col gap-1">
                        <span class="font-bold text-slate-800 text-base">{{ row.name }}</span>
                        <el-tag size="small" :type="getTeamTypeColor(row.team_type)" effect="plain" class="w-fit font-bold">
                            {{ row.team_type }}
                        </el-tag>
                    </div>
                </template>
            </el-table-column>

            <el-table-column label="Đội trưởng" min-width="150">
                <template #default="{ row }">
                    <div class="flex items-center gap-2 text-slate-700">
                        <el-icon><User /></el-icon>
                        <span class="font-medium">{{ row.leader_name || '---' }}</span>
                    </div>
                </template>
            </el-table-column>
            
            <el-table-column label="Liên hệ" width="200">
                <template #default="{ row }">
                    <div class="text-sm flex flex-col gap-1">
                        <div class="flex items-center gap-2">
                            <el-icon class="text-slate-400"><Phone /></el-icon> 
                            <span>{{ row.contact_phone }}</span>
                        </div>
                        <div v-if="row.hotline" class="flex items-center gap-2 text-red-500 font-medium">
                            <el-icon><Phone /></el-icon> 
                            <span>Hotline: {{ row.hotline }}</span>
                        </div>
                    </div>
                </template>
            </el-table-column>

            <el-table-column label="Khu vực hoạt động" min-width="100">
                <template #default="{ row }">
                    <div class="flex flex-col gap-1 text-sm">
                        <span class="font-semibold text-slate-700">{{ row.primary_area }}</span>
                    </div>
                </template>
            </el-table-column>

            <el-table-column label="Trụ sở chính" min-width="250">
                <template #default="{ row }">
                    <div class="flex flex-col gap-1 text-sm">
                        <span class="text-slate-500 truncate" :title="row.address">
                            <el-icon class="mr-1"><House /></el-icon>{{ row.address }}
                        </span>
                    </div>
                </template>
            </el-table-column>

           
            <el-table-column label="Tọa độ" width="160">
                <template #default="{ row }">
                    <div v-if="row.latitude && row.longitude" class="text-xs font-mono text-slate-600 bg-slate-50 p-1 rounded border text-center">
                        <div>Lat: {{ Number(row.latitude).toFixed(4) }}</div>
                        <div>Lng: {{ Number(row.longitude).toFixed(4) }}</div>
                    </div>
                    <span v-else class="text-slate-400 italic text-xs">Chưa có GPS</span>
                </template>
            </el-table-column>

            <el-table-column label="Trạng thái" width="140" align="center">
                <template #default="{ row }">
                    <el-tag 
                        :type="row.status === 'Sẵn sàng' ? 'success' : 'danger'" 
                        effect="dark" 
                        round
                    >
                        {{ row.status }}
                    </el-tag>
                </template>
            </el-table-column>

            <el-table-column width="80" align="center" fixed="right">
                <template #default="{ row }">
                    <el-button :icon="Edit" circle type="primary" @click="openEdit(row)" title="Chỉnh sửa"/>
                </template>
            </el-table-column>
        </el-table>

        <el-dialog v-model="editDialog" title="Cập Nhật Thông Tin Đội Cứu Hộ" width="700px" destroy-on-close align-center>
            <el-form ref="formRef" :model="currentTeam" :rules="rules" label-position="top" class="custom-form">
                
                <el-row :gutter="20">
                    <el-col :span="12">
                        <el-form-item label="Tên đội cứu hộ" prop="name">
                            <el-input v-model="currentTeam.name" placeholder="Nhập tên đội..." />
                        </el-form-item>
                    </el-col>
                    <el-col :span="12">
                        <el-form-item label="Loại hình (Team Type)" prop="team_type">
                            <el-select v-model="currentTeam.team_type" placeholder="Chọn loại hình" class="w-full">
                                <el-option 
                                    v-for="item in TEAM_TYPES" 
                                    :key="item.value" 
                                    :label="item.label" 
                                    :value="item.value" 
                                />
                            </el-select>
                        </el-form-item>
                    </el-col>
                </el-row>

                <el-row :gutter="20">
                    <el-col :span="12">
                        <el-form-item label="Đội trưởng / Quản lý" prop="leader_name">
                            <el-input v-model="currentTeam.leader_name" :prefix-icon="User" placeholder="Họ và tên..." />
                        </el-form-item>
                    </el-col>
                    <el-col :span="12">
                        <el-form-item label="Khu vực phụ trách" prop="primary_area">
                            <el-input v-model="currentTeam.primary_area" :prefix-icon="MapLocation" placeholder="Quận/Huyện..." />
                        </el-form-item>
                    </el-col>
                </el-row>

                <el-row :gutter="20">
                    <el-col :span="12">
                        <el-form-item label="Số điện thoại" prop="contact_phone">
                            <el-input v-model="currentTeam.contact_phone" :prefix-icon="Phone" placeholder="SĐT cá nhân..." />
                        </el-form-item>
                    </el-col>
                    <el-col :span="12">
                        <el-form-item label="Hotline khẩn cấp">
                            <el-input v-model="currentTeam.hotline" :prefix-icon="Phone" placeholder="Đầu số hotline..." />
                        </el-form-item>
                    </el-col>
                </el-row>

                <el-form-item label="Địa chỉ trụ sở" prop="address">
                    <el-input v-model="currentTeam.address" :prefix-icon="House" type="textarea" :rows="2" placeholder="Địa chỉ chi tiết..." />
                </el-form-item>

                <el-divider content-position="left">Cấu hình Vị trí & Trạng thái</el-divider>

                <el-row :gutter="20">
                    <el-col :span="8">
                        <el-form-item label="Vĩ độ (Latitude)" prop="latitude">
                            <el-input-number v-model="currentTeam.latitude" :precision="6" :step="0.0001" class="w-full" controls-position="right" />
                        </el-form-item>
                    </el-col>
                    <el-col :span="8">
                        <el-form-item label="Kinh độ (Longitude)" prop="longitude">
                            <el-input-number v-model="currentTeam.longitude" :precision="6" :step="0.0001" class="w-full" controls-position="right" />
                        </el-form-item>
                    </el-col>
                    <el-col :span="8">
                        <el-form-item label="Trạng thái hiện tại">
                            <el-select v-model="currentTeam.status" class="w-full">
                                <el-option 
                                    v-for="item in TEAM_STATUS" 
                                    :key="item.value" 
                                    :label="item.label" 
                                    :value="item.value"
                                >
                                    <span class="flex items-center gap-2">
                                        <span class="w-2 h-2 rounded-full" :class="`bg-${item.color}-500`"></span>
                                        {{ item.label }}
                                    </span>
                                </el-option>
                            </el-select>
                        </el-form-item>
                    </el-col>
                </el-row>

            </el-form>
            
            <template #footer>
                <div class="dialog-footer pt-4 border-t border-slate-100">
                    <el-button @click="editDialog = false">Hủy bỏ</el-button>
                    <el-button type="primary" :loading="submitting" @click="handleUpdate(formRef)">
                        <el-icon class="mr-1"><Edit /></el-icon> Lưu thay đổi
                    </el-button>
                </div>
            </template>
        </el-dialog>
    </div>
</template>

<style scoped>
/* Tùy chỉnh nhỏ để bảng đẹp hơn */
.custom-table :deep(.el-table__row) {
    cursor: pointer;
}
</style>