<script setup lang="ts">
import { computed } from 'vue';
import { UserFilled, PhoneFilled, MapLocation, PictureFilled, VideoPlay, InfoFilled } from '@element-plus/icons-vue';
import type { RescueRequest } from '@/types/rescue';

const props = defineProps<{ request: RescueRequest }>();

// --- XỬ LÝ MEDIA ---
const MEDIA_BASE_URL = 'http://localhost:8000/media/'; 

const getFullUrl = (path: string) => {
    if (!path) return '';
    if (path.startsWith('http')) return path;
    const baseUrl = MEDIA_BASE_URL.endsWith('/') ? MEDIA_BASE_URL : `${MEDIA_BASE_URL}/`;
    const relativePath = path.startsWith('/') ? path.slice(1) : path;
    return `${baseUrl}${relativePath}`;
};

const isVideo = (path: string) => !!path && !!path.match(/\.(mp4|mov|avi|webm|mkv)$/i);

const imagePreviewList = computed(() => {
    if (!props.request.media_urls) return [];
    return props.request.media_urls.filter(url => !isVideo(url)).map(url => getFullUrl(url));
});
</script>

<template>
    <div class="p-4 space-y-4">
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
                <el-icon><PictureFilled /></el-icon> Hình ảnh / Video:
            </span>
            <div class="grid grid-cols-3 gap-2">
                <div v-for="(mediaPath, index) in request.media_urls" :key="index" class="relative aspect-square rounded-lg overflow-hidden border border-slate-200 bg-slate-100 shadow-sm hover-media-container">
                    <template v-if="isVideo(mediaPath)">
                        <video class="w-full h-full object-cover" controls preload="metadata">
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
                            fit="cover" class="w-full h-full cursor-zoom-in" loading="lazy"
                        />
                    </template>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.hover-media-container:hover :deep(.el-image__inner) { transform: scale(1.1); }
:deep(.el-image__inner) { transition: transform 0.5s ease; width: 100%; height: 100%; object-fit: cover; }
</style>