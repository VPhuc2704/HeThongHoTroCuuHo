<script setup lang="ts">
import { reactive, ref, computed } from 'vue';
import { useAuthStore } from '~/stores/auth.store'; 
import { ElMessage } from 'element-plus';
import { 
  User, Lock, Right, Loading, 
  InfoFilled, Message, Checked, Connection 
} from '@element-plus/icons-vue';

// Sử dụng layout 'auth' (trống, không có header/footer) cho trang login
definePageMeta({ layout: 'auth' });

const authStore = useAuthStore();
const router = useRouter(); // Dùng router để chuyển trang
const isLoginMode = ref(true);

// Form State
const formData = reactive({
  fullName: '',
  email: '',
  password: '',
  confirmPassword: '',
  departmentCode: '' 
});

const pageTitle = computed(() => isLoginMode.value ? 'Đăng nhập hệ thống' : 'Thiết lập định danh');
const pageDesc = computed(() => isLoginMode.value ? 'Nhập thông tin xác thực quyền truy cập.' : 'Đăng ký tài khoản cán bộ mới.');

const toggleMode = () => {
  isLoginMode.value = !isLoginMode.value;
  formData.password = '';
  formData.confirmPassword = '';
};

const handleSubmit = async () => {
  // 1. Validate Form
  if (!formData.email || !formData.password) {
    ElMessage.warning('Vui lòng nhập đầy đủ thông tin bắt buộc.');
    return;
  }

  if (!isLoginMode.value) {
    if (!formData.fullName) {
      ElMessage.warning('Vui lòng nhập họ và tên.');
      return;
    }
    if (formData.password !== formData.confirmPassword) {
      ElMessage.error('Mật khẩu xác nhận không khớp.');
      return;
    }
  }

  try {
    if (isLoginMode.value) {
      
      // 2. Gọi API Login từ Store
      await authStore.login({ identifier: formData.email, password: formData.password });
      
      ElMessage.success({
        message: 'Xác thực thành công. Đang truy cập trung tâm điều hành...',
        type: 'success',
        duration: 1500
      });

      // 3. PHÂN QUYỀN & CHUYỂN HƯỚNG
      const userRole = authStore.user?.role || 'admin';

      setTimeout(() => {
        if (userRole === 'admin' || userRole === 'dispatcher') {
           // Nếu là Admin/Điều phối viên -> Vào trang quản trị
           navigateTo('/admin'); 
        } else {
           // Nếu là Người dân -> Vào trang SOS
           navigateTo('/'); 
        }
      }, 1000); // Delay 1s để user kịp đọc thông báo

    } else {
      // --- XỬ LÝ ĐĂNG KÝ ---
      // await authStore.register(formData); 
      await new Promise(r => setTimeout(r, 1500));
      ElMessage.success('Đăng ký hồ sơ thành công. Vui lòng đăng nhập.');
      toggleMode(); 
    }
  } catch (error: any) {
    ElMessage.error(error.message || 'Tài khoản hoặc mật khẩu không chính xác.');
  }
};
</script>

<template>
  <div class="min-h-screen w-full flex items-center justify-center relative overflow-hidden bg-[#0B1120] font-sans selection:bg-red-500/30 selection:text-red-200">
    
    <div class="absolute inset-0 z-0 pointer-events-none">
      <img 
        src="https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=2070&auto=format&fit=crop" 
        alt="Background" 
        class="w-full h-full object-cover opacity-10 mix-blend-luminosity scale-105" 
      />
      <div class="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-20"></div>
      <div class="absolute inset-0 bg-gradient-to-t from-[#0B1120] via-[#0B1120]/90 to-[#0B1120]/40"></div>
      
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-red-900/10 rounded-full blur-3xl"></div>
    </div>

    <div class="relative z-10 w-full max-w-[900px] bg-[#111827]/60 backdrop-blur-xl border border-gray-700/50 rounded-2xl shadow-2xl flex overflow-hidden ring-1 ring-white/5 animate-fade-in-up">
      
      <div class="hidden md:flex w-[40%] bg-gradient-to-br from-[#1F2937]/80 to-[#111827]/90 flex-col justify-between p-10 relative border-r border-gray-800">
        <div class="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-red-600 to-transparent opacity-50"></div>

        <div>
          <div class="flex items-center gap-4 mb-8">
             <div class="relative group">
               <div class="absolute -inset-1 bg-gradient-to-r from-red-600 to-orange-600 rounded-lg blur opacity-25 group-hover:opacity-50 transition duration-200"></div>
               <div class="relative w-12 h-12 bg-[#1F2937] border border-gray-700 rounded-lg flex items-center justify-center text-red-500 shadow-xl">
                 <el-icon :size="24"><Connection /></el-icon>
               </div>
             </div>
             <div>
               <h1 class="text-2xl font-bold text-white tracking-wide font-display">RESCUELINK</h1>
               <div class="flex items-center gap-2">
                 <span class="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse"></span>
                 <span class="text-[10px] text-gray-400 uppercase tracking-[0.25em]">Command Center</span>
               </div>
             </div>
          </div>
          
          <div class="space-y-6">
            <h3 class="text-gray-200 font-medium text-lg leading-snug">
              Hệ thống quản lý & <br/>điều phối ứng cứu khẩn cấp
            </h3>
            <p class="text-sm text-gray-400 leading-relaxed">
              Kết nối thời gian thực giữa trung tâm chỉ huy và các đơn vị thực địa. Đảm bảo an toàn thông tin cấp độ cao.
            </p>
          </div>
        </div>

        <div class="space-y-4">
           <div class="p-4 rounded-lg bg-[#0B1120]/50 border border-gray-700/50 backdrop-blur-sm">
             <div class="flex items-center justify-between mb-2">
               <span class="text-[10px] text-gray-500 font-mono uppercase">System Status</span>
               <span class="text-[10px] text-green-500 font-mono font-bold flex items-center gap-1">
                 <span class="w-1.5 h-1.5 rounded-full bg-green-500"></span> ONLINE
               </span>
             </div>
             <div class="w-full bg-gray-700 h-1 rounded-full overflow-hidden">
               <div class="bg-green-500 h-full w-[98%] shadow-[0_0_10px_rgba(34,197,94,0.5)]"></div>
             </div>
             <div class="mt-2 text-[10px] text-gray-500 font-mono">Latency: 12ms | Encryption: AES-256</div>
           </div>
           
           <div class="text-[10px] text-gray-600">
             © 2024 National Rescue Committee.
           </div>
        </div>
      </div>

      <div class="w-full md:w-[60%] p-8 md:p-12 flex flex-col justify-center relative">
        
        <div class="mb-8">
          <transition name="fade-slide" mode="out-in">
            <div :key="isLoginMode ? 'login-header' : 'reg-header'">
              <h2 class="text-2xl font-bold text-white mb-2">{{ pageTitle }}</h2>
              <p class="text-gray-400 text-sm">{{ pageDesc }}</p>
            </div>
          </transition>
        </div>

        <el-form :model="formData" size="large" @submit.prevent class="space-y-5 relative">
          
          <transition-group name="list" tag="div" class="space-y-5">
            
            <div v-if="!isLoginMode" key="fullname" class="group">
              <label class="text-[11px] font-bold text-gray-500 mb-1.5 block uppercase tracking-wider">Họ và tên cán bộ</label>
              <el-input 
                v-model="formData.fullName" 
                placeholder="NGUYEN VAN A"
                class="pro-input"
              >
                <template #prefix><el-icon class="text-gray-500"><User /></el-icon></template>
              </el-input>
            </div>

            <div key="email" class="group">
              <label class="text-[11px] font-bold text-gray-500 mb-1.5 block uppercase tracking-wider">SĐT định danh</label>
              <el-input 
                v-model="formData.email" 
                placeholder="0999996868"
                class="pro-input"
              >
                <template #prefix><el-icon class="text-gray-500"><Message /></el-icon></template>
              </el-input>
            </div>

            <div key="password" class="group">
              <label class="text-[11px] font-bold text-gray-500 mb-1.5 block uppercase tracking-wider">Mật khẩu bảo mật</label>
              <el-input 
                v-model="formData.password" 
                type="password" 
                placeholder="••••••••••••" 
                show-password
                class="pro-input"
              >
                <template #prefix><el-icon class="text-gray-500"><Lock /></el-icon></template>
              </el-input>
            </div>

            <div v-if="!isLoginMode" key="confirm" class="group">
              <label class="text-[11px] font-bold text-gray-500 mb-1.5 block uppercase tracking-wider">Xác nhận mật khẩu</label>
              <el-input 
                v-model="formData.confirmPassword" 
                type="password" 
                placeholder="••••••••••••" 
                show-password
                class="pro-input"
              >
                <template #prefix><el-icon class="text-gray-500"><Checked /></el-icon></template>
              </el-input>
            </div>

          </transition-group>

          <div class="pt-2">
            <button 
              class="w-full h-11 bg-gradient-to-r from-red-700 to-red-800 hover:from-red-600 hover:to-red-700 text-white font-semibold rounded-lg shadow-lg shadow-red-900/30 transition-all duration-300 flex items-center justify-center gap-2 text-sm tracking-wide border border-red-900 group"
              :disabled="authStore.loading"
              @click="handleSubmit"
            >
              <span v-if="!authStore.loading" class="group-hover:translate-x-[-2px] transition-transform">
                {{ isLoginMode ? 'XÁC THỰC & TRUY CẬP' : 'GỬI YÊU CẦU ĐĂNG KÝ' }}
              </span>
              <el-icon v-if="!authStore.loading" class="group-hover:translate-x-1 transition-transform"><Right /></el-icon>
              <el-icon v-else class="animate-spin"><Loading /></el-icon>
            </button>
          </div>

          <div class="flex justify-between items-center mt-6 pt-4 border-t border-gray-700/30">
             
             <div class="text-sm text-gray-400">
               <span v-if="isLoginMode">Chưa có tài khoản? </span>
               <span v-else>Đã có tài khoản? </span>
               <button 
                 @click="toggleMode" 
                 class="text-red-400 hover:text-red-300 font-medium transition-colors ml-1 underline underline-offset-4"
               >
                 {{ isLoginMode ? 'Đăng ký cấp quyền' : 'Đăng nhập ngay' }}
               </button>
             </div>

             <a v-if="isLoginMode" href="#" class="text-xs text-gray-500 hover:text-gray-400 transition-colors">Quên mật khẩu?</a>
          </div>

        </el-form>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* CUSTOM FONT */
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500&family=Inter:wght@400;500;600;700&display=swap');

.font-sans { font-family: 'Inter', sans-serif; }
.font-mono { font-family: 'JetBrains Mono', monospace; }

/* PRO INPUT STYLING */
:deep(.pro-input .el-input__wrapper) {
  background-color: rgba(17, 24, 39, 0.5) !important; /* Semi-transparent */
  border: 1px solid #374151;
  border-radius: 8px;
  box-shadow: none !important;
  padding: 0 12px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Hover State */
:deep(.pro-input .el-input__wrapper:hover) {
  border-color: #4B5563;
  background-color: rgba(17, 24, 39, 0.8) !important;
}

/* Focus State */
:deep(.pro-input .el-input__wrapper.is-focus) {
  border-color: #B91C1C; 
  background-color: rgba(11, 17, 32, 1) !important;
  box-shadow: 0 0 0 1px rgba(185, 28, 28, 0.2) !important;
}

:deep(.pro-input .el-input__inner) {
  color: #F3F4F6 !important;
  height: 44px;
  font-family: 'JetBrains Mono', monospace; /* Tech vibe for text */
  font-size: 13px;
}

:deep(.pro-input .el-input__inner::placeholder) {
  color: #4B5563;
}

/* ANIMATIONS */
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.animate-fade-in-up {
  animation: fadeInUp 0.6s ease-out forwards;
}

/* VUE TRANSITIONS */
/* List transition (cho input fields) */
.list-enter-active,
.list-leave-active {
  transition: all 0.4s ease;
}
.list-enter-from,
.list-leave-to {
  opacity: 0;
  transform: translateX(-10px); /* Trượt nhẹ sang trái */
  height: 0; /* Thu gọn chiều cao */
  margin: 0;
  overflow: hidden;
}

/* Fade Slide (cho Header) */
.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.3s ease;
}
.fade-slide-enter-from {
  opacity: 0;
  transform: translateY(-10px);
}
.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
</style>