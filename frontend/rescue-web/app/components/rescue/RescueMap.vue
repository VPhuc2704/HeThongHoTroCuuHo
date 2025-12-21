<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { LMap, LTileLayer, LMarker, LPolyline, LPopup, LIcon } from '@vue-leaflet/vue-leaflet';
import 'leaflet/dist/leaflet.css';
import type { RescueRequest } from '@/types/rescue';

const props = defineProps<{
    request: RescueRequest;
}>();

const zoom = ref(13);
const map = ref(null);

// Tính toán đường nối
const connectionLine = computed(() => {
    if (props.request.active_assignment) {
        return [
            [props.request.latitude, props.request.longitude],
            [props.request.active_assignment.team_lat, props.request.active_assignment.team_lng]
        ] as [number, number][]; // Ép kiểu để Leaflet không báo lỗi
    }
    return [];
});

// Auto zoom
watch(() => props.request, (newVal) => {
    if (newVal.active_assignment) {
        zoom.value = 13; // Zoom xa thấy cả 2
    } else {
        zoom.value = 15; // Zoom gần nạn nhân
    }
}, { deep: true });

onMounted(async () => {
    if (typeof window !== 'undefined') {
        const L = await import('leaflet');
        // Fix lỗi icon mặc định của Leaflet
        type IconDefaultType = any;
        delete (L.Icon.Default.prototype as IconDefaultType)._getIconUrl;
        L.Icon.Default.mergeOptions({
            iconRetinaUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon-2x.png',
            iconUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-icon.png',
            shadowUrl: 'https://unpkg.com/leaflet@1.7.1/dist/images/marker-shadow.png',
        });
    }
});
</script>

<template>
    <div class="h-full w-full z-0">
        <ClientOnly>
            <l-map 
                ref="map" 
                v-model:zoom="zoom" 
                :center="[request.latitude, request.longitude]"
                :use-global-leaflet="false"
            >
                <l-tile-layer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"></l-tile-layer>
                
                <l-marker :lat-lng="[request.latitude, request.longitude]">
                    <l-popup>Nạn nhân: {{ request.name }}</l-popup>
                </l-marker>

                <template v-if="request.active_assignment">
                    <l-marker :lat-lng="[request.active_assignment.team_lat, request.active_assignment.team_lng]">
                        <l-icon
                            icon-url="https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-green.png"
                            :icon-size="[25, 41]"
                            :icon-anchor="[12, 41]"
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
        </ClientOnly>
        
        <div class="absolute bottom-1 left-1 bg-white/90 px-2 py-1 rounded text-[10px] font-mono shadow z-[1000]">
            {{ request.latitude.toFixed(6) }}, {{ request.longitude.toFixed(6) }}
        </div>
    </div>
</template>