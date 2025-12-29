<script setup lang="ts">
import { useRoute } from 'vue-router';
import { 
  Monitor, List, User, Setting, FirstAidKit,
  Bell, Search, SwitchButton, Menu as IconMenu,
  Location, DataAnalysis, CircleCheck
} from '@element-plus/icons-vue';

const route = useRoute();
const authStore = useAuthStore();

const menuItems = [
  { 
    group: 'Điều Hành',
    items: [
      { name: 'Tổng quan', path: '/admin', icon: Monitor },
      { name: 'Bản đồ trực chiến', path: '/admin/map', icon: Location },
    ]
  },
  { 
    group: 'Quản Lý Sự Cố',
    items: [
      { name: 'Danh sách sự cố', path: '/admin/incidents', icon: List },
      { name: 'Danh sách nhiệm vụ', path: '/admin/tasks', icon: List },
      { name: 'Phân tích dữ liệu', path: '/admin/analytics', icon: DataAnalysis },
    ]
  },
  { 
    group: 'Hệ Thống',
    items: [
      { name: 'Người dùng & Cán bộ', path: '/admin/accounts', icon: User },
      { name: 'Đội Cứu Hộ', path: '/admin/teams', icon: FirstAidKit },
      { name: 'Cấu hình hệ thống', path: '/admin/settings', icon: Setting },
      { name: 'Kiểm tra kết nối', path: '/admin/check', icon: CircleCheck },
    ]
  }
];

const handleLogout = () => {
  ElMessageBox.confirm(
    'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?',
    'Xác nhận đăng xuất',
    {
      confirmButtonText: 'Đăng xuất',
      cancelButtonText: 'Hủy',
      type: 'warning',
      confirmButtonClass: 'el-button--danger'
    }
  )
    .then(async () => {
      // Gọi hàm từ service
      await authStore.logout();
      ElMessage.success('Đã đăng xuất thành công');
    })
    .catch(() => {
      // User bấm hủy, không làm gì cả
    });
  navigateTo('/login');
}
</script>

<template>
  <div class="flex h-screen bg-slate-50 font-sans text-slate-600">
    
    <aside class="w-72 bg-[#0f172a] text-slate-200 flex flex-col transition-all duration-300 border-r border-slate-800 shadow-2xl z-20">
      
      <div class="h-16 flex items-center px-6 border-b border-slate-800 bg-[#0B1120]">
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-red-600 to-red-800 flex items-center justify-center shadow-lg shadow-red-900/50">
            <el-icon class="text-white text-lg font-bold"><Location /></el-icon>
          </div>
          <div>
            <h1 class="text-white font-extrabold text-lg tracking-tight leading-none">RESCUE<span class="text-red-500">LINK</span></h1>
            <p class="text-[10px] text-slate-500 uppercase tracking-widest font-semibold mt-0.5">Admin Portal</p>
          </div>
        </div>
      </div>

      <nav class="flex-1 overflow-y-auto py-6 px-4 space-y-8 scrollbar-hide">
        <div v-for="(group, index) in menuItems" :key="index">
          <h3 class="px-3 text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">{{ group.group }}</h3>
          
          <ul class="space-y-1 list-none">
            <li v-for="item in group.items" :key="item.path">
              <NuxtLink 
                :to="item.path" 
                class="flex items-center gap-3 px-3 py-3 rounded-lg text-sm font-medium transition-all duration-200 group relative overflow-hidden"
                
                :class="route.path === item.path 
                    ? 'bg-slate-800 text-white font-semibold shadow-inner shadow-slate-900/50 ring-1 ring-red-700/50' 
                    : 'text-slate-400 hover:bg-slate-800/70 hover:text-slate-300'"
              >
                <div 
                    class="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-0 bg-red-500 rounded-r-full transition-all duration-200"
                    :class="route.path === item.path ? 'h-full opacity-100' : 'h-0 opacity-0'"
                ></div>
                
                <el-icon :size="18" 
                    :class="route.path === item.path ? 'text-red-500' : 'text-slate-500 group-hover:text-red-400'" 
                    class="transition-colors ml-1"
                >
                  <component :is="item.icon" />
                </el-icon>
                <span>{{ item.name }}</span>
              </NuxtLink>
            </li>
          </ul>
        </div>
      </nav>

      <div class="p-4 border-t border-slate-800 bg-[#0B1120] mt-auto">
        <div class="flex items-center gap-3 p-2 rounded-lg transition">
          <div class="relative">
            <img src="https://i.pravatar.cc/150?u=admin" alt="Admin" class="w-10 h-10 rounded-full border-2 border-green-500" />
            <span class="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-[#0B1120] rounded-full"></span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-white truncate">Admin Manager</p>
            <p class="text-xs text-slate-500 truncate">Online</p>
          </div>
          <button class="p-2 rounded-full hover:bg-slate-700 transition" @click="handleLogout">
              <el-icon class="text-slate-500 hover:text-red-500 transition"><SwitchButton /></el-icon>
          </button>
        </div>
      </div>
    </aside>

    <div class="flex-1 flex flex-col h-screen overflow-hidden relative">
      
      <header class="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-6 z-10 shadow-sm">
        
        <div class="flex items-center gap-4">
          <button class="p-2 text-slate-400 hover:text-slate-600 lg:hidden">
            <el-icon :size="20"><IconMenu /></el-icon>
          </button>
          
          <div class="relative hidden md:block">
            <el-icon class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"><Search /></el-icon>
            <input 
              type="text" 
              placeholder="Tìm kiếm hồ sơ, sự cố..." 
              class="pl-9 pr-4 py-2 bg-slate-100 border-none rounded-full text-sm focus:ring-2 focus:ring-red-100 focus:bg-white transition-all w-64"
            />
          </div>
        </div>

        <div class="flex items-center gap-4">
          <button class="relative p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-full transition">
            <el-icon :size="20"><Bell /></el-icon>
            <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white animate-pulse"></span>
          </button>
          
          <div class="h-8 w-px bg-slate-200 mx-1"></div>
          
          <div class="text-right hidden md:block">
            <p class="text-xs font-bold text-slate-700">Trung Tâm Chỉ Huy</p>
            <p class="text-[10px] text-green-600 font-medium">● Hệ thống ổn định</p>
          </div>
        </div>
      </header>

      <main class="flex-1 overflow-auto bg-slate-50 p-6">
          <div class="mb-6">
              
              <div class="text-sm text-slate-500 flex items-center gap-1">
                  <span class="text-xs text-slate-400">Home / Admin / </span>
                  <span class="text-slate-800 font-medium">
                      {{ menuItems.flatMap(g => g.items).find(i => i.path === route.path)?.name || 'Dashboard' }}
                  </span>
              </div>

              <h2 class="text-3xl font-bold text-slate-900 tracking-tight mt-2">
                  {{ menuItems.flatMap(g => g.items).find(i => i.path === route.path)?.name || 'Dashboard' }}
              </h2>
          </div>

          <div class="animate-fade-in-up">
            <slot />
          </div>
      </main>

    </div>
  </div>
</template>

<style scoped>
/* Tùy chỉnh thanh cuộn cho gọn */
.scrollbar-hide::-webkit-scrollbar {
    display: none;
}
.scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
}

/* Hiệu ứng load trang nhẹ nhàng */
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in-up {
  animation: fadeInUp 0.4s ease-out forwards;
}
</style>

