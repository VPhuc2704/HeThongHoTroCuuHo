<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { 
    InfoFilled, UserFilled, PhoneFilled, MapLocation, 
    PictureFilled, VideoPlay, Van 
} from '@element-plus/icons-vue';
import type { RescueRequest } from '@/types/rescue';
import { LMap, LTileLayer, LMarker, LPopup, LPolyline, LIcon } from '@vue-leaflet/vue-leaflet';
import 'leaflet/dist/leaflet.css';
import { ElMessage } from 'element-plus';
import RescueDispatch from './RescueDispatch.vue';

// --- IMPORT ICONS TRỰC TIẾP ---
import iconUrl from 'leaflet/dist/images/marker-icon.png';
import iconRetinaUrl from 'leaflet/dist/images/marker-icon-2x.png';
import shadowUrl from 'leaflet/dist/images/marker-shadow.png';

const props = defineProps<{
    request: RescueRequest | null;
}>();

const emit = defineEmits(['refresh']);
const MEDIA_BASE_URL = 'http://localhost:8000/media/'; 

const zoom = ref(13);
const map = ref(null);
const showDispatchDialog = ref(false);
const isBrowser = ref(false);

const getFullUrl = (path: string) => {
    if (!path) return '';
    if (path.startsWith('http')) return path; 
    const baseUrl = MEDIA_BASE_URL.endsWith('/') ? MEDIA_BASE_URL : `${MEDIA_BASE_URL}/`;
    const relativePath = path.startsWith('/') ? path.slice(1) : path;
    return `${baseUrl}${relativePath}`;
};

const isVideo = (path: string) => {
    if (!path) return false;
    return !!path.match(/\.(mp4|mov|avi|webm|mkv)$/i);
};

const imagePreviewList = computed(() => {
    if (!props.request?.media_urls) return [];
    return props.request.media_urls
        .filter((url: string) => !isVideo(url))
        .map((url: string) => getFullUrl(url));
});

// --- FIX LỖI TYPE SCRIPT ---
const connectionLine = computed(() => {
    if (props.request && props.request.active_assignment) {
        return [
            [props.request.latitude, props.request.longitude] as [number, number], 
            [props.request.active_assignment.team_lat, props.request.active_assignment.team_lng] as [number, number]
        ];
    }
    return [];
});

const handleOpenDispatch = () => {
    if (!props.request) return;
    showDispatchDialog.value = true;
};

const onAssignSuccess = () => {
    ElMessage.success('Điều động đội cứu hộ thành công!');
    showDispatchDialog.value = false;
    emit('refresh'); 
};

watch(() => props.request, (newVal) => {
    if (newVal && newVal.active_assignment) {
        zoom.value = 13; 
    } else if (newVal) {
        zoom.value = 15; 
    }
});

onMounted(() => {
    isBrowser.value = true;
    // Không cần hack L.Icon.Default nữa
});
</script>

<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col h-full overflow-hidden">
        <div class="p-4 border-b flex items-center gap-3 bg-slate-50 border-slate-100">
            <el-icon class="text-blue-600" :size="20"><InfoFilled /></el-icon>
            <h3 class="font-bold text-slate-800 text-base uppercase tracking-wide">Chi tiết Yêu cầu</h3>
            
            <el-tag v-if="request?.active_assignment" type="success" size="small" class="ml-auto font-bold">
                {{ request.active_assignment.status }}
            </el-tag>
            <el-tag v-else-if="request" type="warning" size="small" class="ml-auto font-bold">
                Chờ xử lý
            </el-tag>
        </div>

        <div v-if="request" class="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
            
            <div class="h-60 rounded-lg overflow-hidden border border-slate-300 relative z-0 shadow-sm">
                <div v-if="isBrowser" class="h-full w-full">
                    <l-map 
                        ref="map" 
                        v-model:zoom="zoom" 
                        :center="[request.latitude, request.longitude]"
                        :use-global-leaflet="false"
                        class="h-full w-full"
                    >
                        <l-tile-layer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"></l-tile-layer>
                        
                        <l-marker :lat-lng="[request.latitude, request.longitude]">
                            <l-icon
                                :icon-url="iconUrl"
                                :icon-retina-url="iconRetinaUrl"
                                :shadow-url="shadowUrl"
                                :icon-size="[25, 41]"
                                :icon-anchor="[12, 41]"
                                :popup-anchor="[1, -34]"
                                :shadow-size="[41, 41]"
                            />
                            <l-popup>
                                <div class="text-center">
                                    <b>{{ request.name }}</b><br>
                                    <span class="text-xs text-red-500 font-bold">Vị trí gặp nạn</span>
                                </div>
                            </l-popup>
                        </l-marker>

                        <template v-if="request.active_assignment">
                             <l-marker :lat-lng="[request.active_assignment.team_lat, request.active_assignment.team_lng]">
                                <l-icon
                                    icon-url="https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-green.png"
                                    :icon-size="[25, 41]"
                                    :icon-anchor="[12, 41]"
                                    :popup-anchor="[1, -34]"
                                    :shadow-url="shadowUrl"
                                    :shadow-size="[41, 41]"
                                />
                                <l-popup>
                                    <b>{{ request.active_assignment.team_name }}</b><br>
                                    {{ request.active_assignment.team_phone }}
                                </l-popup>
                            </l-marker>

                            <l-polyline 
                                :lat-lngs="connectionLine" 
                                color="blue" 
                                :weight="3" 
                                :opacity="0.6" 
                                dash-array="10, 10"
                            />
                        </template>
                    </l-map>
                </div>
                
                <div class="absolute bottom-1 left-1 bg-white/90 px-2 py-1 rounded text-[10px] font-mono shadow z-[1000]">
                    {{ request.latitude.toFixed(6) }}, {{ request.longitude.toFixed(6) }}
                </div>
            </div>

            <div class="bg-blue-50 p-4 rounded-xl border border-blue-100 flex items-center gap-4 shadow-sm">
                <el-avatar :icon="UserFilled" class="bg-blue-600 text-white shadow-md shrink-0" :size="48" />
                <div class="flex flex-col justify-center">
                    <p class="font-extrabold text-slate-800 text-lg leading-tight mb-1">{{ request.name }}</p>
                    <div class="flex items-center gap-2 text-slate-600 bg-white/60 px-2 py-0.5 rounded-md w-fit border border-blue-100">
                        <el-icon :size="14"><PhoneFilled /></el-icon> 
                        <a :href="`tel:${request.contact_phone}`" class="hover:text-blue-700 font-bold text-sm transition-colors">{{ request.contact_phone }}</a>
                    </div>
                </div>
            </div>

            <div class="grid grid-cols-3 gap-2 text-center">
                <div class="bg-slate-50 p-2 rounded border border-slate-100">
                    <div class="text-xl font-bold text-slate-800">{{ request.adults }}</div>
                    <div class="text-xs text-slate-500 uppercase font-semibold">Lớn</div>
                </div>
                <div class="bg-slate-50 p-2 rounded border border-slate-100">
                    <div class="text-xl font-bold text-slate-800">{{ request.children }}</div>
                    <div class="text-xs text-slate-500 uppercase font-semibold">Nhỏ</div>
                </div>
                <div class="bg-slate-50 p-2 rounded border border-slate-100">
                    <div class="text-xl font-bold text-slate-800">{{ request.elderly || 0 }}</div>
                    <div class="text-xs text-slate-500 uppercase font-semibold">Già</div>
                </div>
            </div>

            <div v-if="request.conditions?.length" class="space-y-2">
                <span class="text-xs font-bold text-red-600 uppercase tracking-wider flex items-center gap-1">
                    <el-icon><InfoFilled /></el-icon> Cần hỗ trợ:
                </span>
                <div class="flex flex-wrap gap-2">
                    <el-tag v-for="(cond, idx) in request.conditions" :key="idx" type="danger" effect="dark" round>
                        {{ cond }}
                    </el-tag>
                </div>
            </div>
            
            <div class="space-y-3 text-sm border-t border-slate-100 pt-4">
                <div>
                    <span class="text-slate-400 text-xs font-bold uppercase mb-1 block">Địa chỉ:</span>
                    <div class="flex gap-2 text-slate-800 font-medium bg-slate-50 p-2 rounded border border-slate-200">
                        <el-icon class="mt-1 text-red-500 shrink-0"><MapLocation /></el-icon>
                        {{ request.address }}
                    </div>
                </div>
                <div>
                    <span class="text-slate-400 text-xs font-bold uppercase mb-1 block">Mô tả:</span>
                    <p class="text-slate-600 italic leading-relaxed pl-3 border-l-4 border-slate-200 bg-slate-50/50 py-1 pr-1 rounded-r">
                        "{{ request.description_short}}"
                    </p>
                </div>
            </div>

            <div v-if="request.media_urls && request.media_urls.length > 0" class="pt-2 border-t border-slate-100">
                 <span class="text-slate-400 text-xs font-bold uppercase mb-2 block flex items-center gap-1">
                    <el-icon><PictureFilled /></el-icon> Hình ảnh / Video hiện trường:
                </span>
                
                <div class="grid grid-cols-3 gap-2">
                    <div 
                        v-for="(mediaPath, index) in request.media_urls" 
                        :key="index"
                        class="relative aspect-square rounded-lg overflow-hidden border border-slate-200 bg-slate-100 shadow-sm hover-media-container"
                    >
                        <template v-if="isVideo(mediaPath)">
                            <video 
                                class="w-full h-full object-cover" 
                                controls 
                                preload="metadata"
                            >
                                <source :src="getFullUrl(mediaPath)" type="video/mp4">
                            </video>
                            <div class="absolute top-1 right-1 bg-black/50 text-white rounded-full p-1 pointer-events-none">
                                <el-icon :size="12"><VideoPlay /></el-icon>
                            </div>
                        </template>

                        <template v-else>
                            <el-image 
                                :src="getFullUrl(mediaPath)" 
                                :preview-src-list="imagePreviewList"
                                :initial-index="imagePreviewList.indexOf(getFullUrl(mediaPath))"
                                fit="cover"
                                class="w-full h-full cursor-zoom-in custom-el-image"
                                loading="lazy"
                            >
                                <template #error>
                                    <div class="flex justify-center items-center w-full h-full text-slate-300">
                                        <el-icon :size="20"><PictureFilled /></el-icon>
                                    </div>
                                </template>
                            </el-image>
                        </template>
                    </div>
                </div>
            </div>

            <div class="pt-2 mt-auto sticky bottom-0 bg-white pb-2 border-t border-slate-100">
                
                <div v-if="request.active_assignment" class="bg-green-50 border border-green-200 rounded-lg p-3 shadow-sm">
                    <div class="flex items-center justify-between mb-2">
                        <span class="text-xs font-bold text-green-700 uppercase flex items-center gap-1">
                            <el-icon><Van /></el-icon> Đang thực hiện nhiệm vụ
                        </span>
                        <span class="text-[10px] text-green-600 bg-green-100 px-2 py-0.5 rounded-full">
                            {{ request.active_assignment.updated_at ? 'Vừa cập nhật' : '' }}
                        </span>
                    </div>
                    
                    <div class="flex items-center gap-3">
                        <div class="bg-white p-2 rounded-full border border-green-100 shadow-sm">
                            <el-icon class="text-green-600 text-xl"><Van /></el-icon>
                        </div>
                        <div>
                            <p class="font-bold text-slate-800 text-sm">{{ request.active_assignment.team_name }}</p>
                            <p class="text-xs text-slate-500 font-mono">{{ request.active_assignment.team_phone || 'Chưa có SĐT' }}</p>
                        </div>
                    </div>

                    <div class="flex gap-2 mt-3">
                        <el-button size="small" type="primary" plain class="flex-1">Gọi điện</el-button>
                        <el-button size="small" type="danger" text bg class="flex-1">Hủy Đội</el-button>
                    </div>
                </div>

                <el-button 
                    v-else
                    type="danger" 
                    class="w-full h-12 text-lg font-bold shadow-lg shadow-red-100 transition-transform active:scale-95" 
                    :icon="UserFilled" 
                    @click="handleOpenDispatch"
                >
                    ĐIỀU ĐỘNG CỨU HỘ
                </el-button>
            </div>
        </div>

        <div v-else class="flex-1 flex flex-col items-center justify-center text-slate-400 p-8 text-center bg-slate-50/50">
            <el-icon class="text-6xl mb-4 opacity-20"><MapLocation /></el-icon>
            <p class="font-medium">Chọn một yêu cầu từ danh sách<br>để xem vị trí và chi tiết</p>
        </div>

        <RescueDispatch
            v-model="showDispatchDialog"
            :request="request"
            @success="onAssignSuccess"
        />
    </div>
</template>

<style scoped>
.hover-media-container:hover :deep(.el-image__inner) {
    transform: scale(1.1);
}

:deep(.el-image__inner) {
    transition: transform 0.5s ease;
    width: 100%;
    height: 100%;
    object-fit: cover;
}

:deep(.el-image), :deep(.el-image__inner) {
    touch-action: none; 
}

.custom-scrollbar::-webkit-scrollbar {
    width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
    background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
    background-color: #cbd5e1;
    border-radius: 20px;
}
</style>