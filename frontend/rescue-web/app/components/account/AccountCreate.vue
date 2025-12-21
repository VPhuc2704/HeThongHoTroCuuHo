<script setup lang="ts">
import { reactive, ref, watch } from 'vue';
import { ElMessage } from 'element-plus';
import type { FormInstance, FormRules } from 'element-plus';
import type { CreateAccountPayload } from '~/types/account';

const props = defineProps<{
    modelValue: boolean; // v-model cho dialog
}>();

const emit = defineEmits(['update:modelValue', 'success']);

// Dùng service
const { createAccount } = useAdminService();

const formRef = ref<FormInstance>();
const submitting = ref(false);

const form = reactive<CreateAccountPayload>({
    email: '',
    password: '',
    role_code: 'RESCUER', // Mặc định
    phone: ''
});

// Reset form mỗi khi mở dialog
watch(() => props.modelValue, (val) => {
    if (val) {
        form.email = '';
        form.password = '';
        form.phone = '';
        form.role_code = 'RESCUER';
        // Clear validation cũ
        setTimeout(() => formRef.value?.clearValidate(), 50); 
    }
});

const rules = reactive<FormRules>({
    email: [
        { required: true, message: 'Vui lòng nhập Email', trigger: 'blur' },
        { type: 'email', message: 'Email không đúng định dạng', trigger: ['blur', 'change'] }
    ],
    password: [
        { required: true, message: 'Vui lòng nhập mật khẩu', trigger: 'blur' },
        { min: 6, message: 'Mật khẩu tối thiểu 6 ký tự', trigger: 'blur' }
    ],
    role_code: [
        { required: true, message: 'Vui lòng chọn vai trò', trigger: 'change' }
    ]
});

const handleClose = () => {
    emit('update:modelValue', false);
};

const handleSubmit = async () => {
    if (!formRef.value) return;
    await formRef.value.validate(async (valid) => {
        if (valid) {
            submitting.value = true;
            try {
                await createAccount(form);
                ElMessage.success('Tạo tài khoản thành công');
                emit('success'); // Báo cho cha reload data
                handleClose();
            } catch (e: any) {
                // Giả sử API trả lỗi dạng { data: { message: ... } }
                const msg = e.response?._data?.message || e.message || 'Có lỗi xảy ra';
                ElMessage.error(msg);
            } finally {
                submitting.value = false;
            }
        }
    });
};
</script>

<template>
    <el-dialog 
        :model-value="modelValue" 
        @update:model-value="handleClose"
        title="Thêm Tài Khoản Mới" 
        width="500px"
        destroy-on-close
        center
        class="rounded-xl"
        append-to-body
    >
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" class="mt-2 px-2">
            <el-form-item label="Email đăng nhập" prop="email">
                <el-input v-model="form.email" placeholder="email@example.com" />
            </el-form-item>
            
            <el-form-item label="Mật khẩu" prop="password">
                <el-input v-model="form.password" type="password" show-password placeholder="••••••" />
            </el-form-item>
            
            <div class="grid grid-cols-2 gap-4">
                <el-form-item label="Số điện thoại" prop="phone">
                    <el-input v-model="form.phone" placeholder="09xxxx" />
                </el-form-item>
                <el-form-item label="Vai trò" prop="role_code">
                    <el-select v-model="form.role_code" class="w-full">
                        <el-option label="Người dân" value="CITIZEN" />
                        <el-option label="Đội cứu hộ" value="RESCUER" />
                        <el-option label="Quản trị viên" value="ADMIN" />
                    </el-select>
                </el-form-item>
            </div>
        </el-form>
        <template #footer>
            <div class="flex justify-end gap-3">
                <el-button @click="handleClose">Hủy</el-button>
                <el-button type="primary" :loading="submitting" @click="handleSubmit">
                    Xác nhận
                </el-button>
            </div>
        </template>
    </el-dialog>
</template>