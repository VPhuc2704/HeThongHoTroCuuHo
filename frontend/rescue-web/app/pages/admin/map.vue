<script setup lang="ts">
import { ref, onMounted, nextTick } from 'vue';
import { LocationFilled } from '@element-plus/icons-vue';
// Đảm bảo đường dẫn import đúng
import MapWidget from '~/components/MapWidget.vue'; 
import { useRealtimeMap } from '~/composables/useRealtimeMap';
import type { MapBounds } from '~/types/map';

definePageMeta({ layout: 'admin', hideHeader: true });

// Lấy logic fetch data từ composable có sẵn của bạn
const { points, socketStatus, fetchPoints } = useRealtimeMap();

const userLocation = ref<[number, number]>([0, 0]);
let geoLocationWatchId: number | null = null;

// --- Logic Geolocation ---
const getUserLocation = (watch = false) => {
  if (!navigator.geolocation) {
    console.error("Trình duyệt không hỗ trợ Geolocation.");
    return;
  }

  const options = {
    enableHighAccuracy: false, // Tắt để tiết kiệm pin và nhanh hơn
    timeout: 10000,
    maximumAge: 60000 // Cache 1 phút
  };

  const successCallback = (position: GeolocationPosition) => {
    const { latitude, longitude } = position.coords;
    userLocation.value = [latitude, longitude];
    console.log("📍 Updated Location:", userLocation.value);
  };

  const errorCallback = (error: GeolocationPositionError) => {
    console.warn("⚠️ Lỗi lấy vị trí:", error.message);
    // Có thể thêm thông báo UI ở đây (ElMessage)
  };

  // Nếu đang watch rồi thì không tạo thêm
  if (watch) {
    if (geoLocationWatchId !== null) navigator.geolocation.clearWatch(geoLocationWatchId);
    
    geoLocationWatchId = navigator.geolocation.watchPosition(
      successCallback, 
      errorCallback, 
      options
    );
  } else {
    navigator.geolocation.getCurrentPosition(successCallback, errorCallback, options);
  }
};

const handleLocationClick = () => {
  // Khi bấm nút, force lấy lại vị trí hiện tại chính xác nhất
  getUserLocation(false);
  
  // Nếu muốn bật chế độ theo dõi liên tục khi bấm nút:
  // getUserLocation(true); 
};

// Gọi handleFetchData từ MapWidget emit ra
const handleFetchData = (bounds: MapBounds) => {
    fetchPoints(bounds);
};

onMounted(async () => {
  await nextTick();
  // Lấy vị trí ngay khi load trang
  getUserLocation(false);
});
</script>

<template>
    <div class="h-[calc(100vh-0px)] flex flex-col">
        <div class="flex-1 bg-slate-900 relative">
            <ClientOnly>
                <MapWidget 
                    :points="points" 
                    :user-location="userLocation"
                    @fetch-new-data="handleFetchData" 
                />
            </ClientOnly>
            
            <button 
                @click="handleLocationClick"
                class="absolute bottom-6 right-6 z-[1000] bg-white text-slate-700 p-3 rounded-full shadow-lg hover:bg-slate-100 transition-transform active:scale-95"
                title="Vị trí của tôi"
            >
                <el-icon :size="24" class="text-blue-600"><LocationFilled /></el-icon>
            </button>
            
            <div v-if="socketStatus === 'CLOSED'" class="absolute top-4 right-4 z-[1000] bg-red-500 text-white px-3 py-1 rounded text-xs">
                Mất kết nối
            </div>
        </div>
    </div>
</template>