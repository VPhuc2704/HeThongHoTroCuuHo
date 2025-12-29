<template>
  <div class="w-full h-full relative z-0 min-h-[500px]">
    <l-map
      ref="mapRef"
      v-model:zoom="currentZoom"
      :center="mapCenter"
      :options="mapOptions"
      @ready="onMapReady"
      @moveend="onMapMoveEnd"
    >
      <l-tile-layer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        layer-type="base"
        name="OpenStreetMap"
        :max-zoom="19"
      />
      
      <l-marker v-if="isValidUserLocation" :lat-lng="userLatLng" :z-index-offset="1000">
        <l-popup>Vị trí của bạn</l-popup>
      </l-marker>
    </l-map>
  </div>
</template>
<script setup lang="ts">
import { ref, watch, computed, onBeforeUnmount, shallowRef, type PropType } from 'vue';
import { LMap, LTileLayer, LMarker, LPopup } from '@vue-leaflet/vue-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useMapIcons } from '~/composables/useMapIcons';
// Import đúng type vừa sửa
import type { MapPoint, BackendPoint, MapItem, MapBounds } from '~/types/map';

// --- 2. Props & Emits ---
const props = defineProps({
  // Props nhận vào mảng hỗn hợp (Cả Point và Cluster)
  points: { type: Array as PropType<MapItem[]>, default: () => [] },
  userLocation: { type: Array as PropType<number[]>, default: () => [0, 0] },
});

const emit = defineEmits<{
  (e: 'fetch-new-data', bounds: MapBounds): void
}>();

// --- 3. Setup & Config ---
const { getIcon } = useMapIcons();
const currentZoom = ref(13);
const mapOptions = { zoomControl: true, attributionControl: false, minZoom: 5, maxZoom: 19 };

// --- 4. State Management ---
const mapInstance = shallowRef<L.Map | null>(null);
const markersLayer = shallowRef<L.LayerGroup | null>(null);
const activeMarkers = new Map<string, L.Marker>(); 

let debounceTimer: ReturnType<typeof setTimeout>;
let lastFetchedBounds: L.LatLngBounds | null = null;
let lastZoom = 0;

// --- 5. Computed Properties ---
const isValidUserLocation = computed(() => 
  Array.isArray(props.userLocation) && props.userLocation.length === 2 && props.userLocation[0] !== 0
);

const userLatLng = computed((): [number, number] => 
  isValidUserLocation.value ? [props.userLocation[0]!, props.userLocation[1]!] : [0, 0]
);

const mapCenter = computed((): [number, number] => 
  isValidUserLocation.value ? userLatLng.value : [10.7769, 106.7009]
);

// --- 6. Helper Functions ---
// Hàm này chấp nhận cả 2 loại vì cả 2 đều có lat/lng
const parseLatLng = (p: MapItem): [number, number] | null => {
  const lat = Number(p.latitude);
  const lng = Number(p.longitude);
  return (isNaN(lat) || isNaN(lng)) ? null : [lat, lng];
};

const getStatusColor = (status?: string | null) => {
  if (!status) return '#6b7280'; // Màu xám (Mặc định)
  
  // Chuẩn hóa chuỗi về chữ thường để so sánh chính xác
  const s = String(status).toLowerCase().trim();

  switch (s) {
    case 'chờ xử lý':
      return '#dc2626'; // Red-600 (Khẩn cấp)
    case 'đã phân công':
      return '#d97706'; // Amber-600 (Cảnh báo/Chờ)
    case 'đang thực hiện':
      return '#2563eb'; // Blue-600 (Đang hoạt động)
    case 'hoàn thành':
      return '#16a34a'; // Green-600 (Thành công)
    case 'an toàn':
      return '#0891b2'; // Cyan-600 (Trạng thái tốt)
    default:
      return '#6b7280'; // Gray (Không xác định)
  }
};

const getStatusBg = (status?: string | null) => {
  if (!status) return '#f3f4f6';
  
  const s = String(status).toLowerCase().trim();

  switch (s) {
    case 'chờ xử lý':
      return '#fee2e2'; // Red-100
    case 'đã phân công':
      return '#fef3c7'; // Amber-100
    case 'đang thực hiện':
      return '#dbeafe'; // Blue-100
    case 'hoàn thành':
      return '#dcfce7'; // Green-100
    case 'an toàn':
      return '#cffafe'; // Cyan-100
    default:
      return '#f3f4f6';
  }
};

// --- HÀM TẠO HTML POPUP (Chỉ dành cho MapPoint) ---
const createPopupContent = (p: MapPoint) => {
    const statusColor = getStatusColor(p.status);
    const statusBg = getStatusBg(p.status);
    
    // Tổng hợp nhân khẩu
    const totalPeople = (p.adults || 0) + (p.children || 0) + (p.elderly || 0);
    const detailsArr = [];
    if (p.adults) detailsArr.push(`${p.adults} lớn`);
    if (p.children) detailsArr.push(`${p.children} nhỏ`);
    if (p.elderly) detailsArr.push(`${p.elderly} già`);
    const peopleDetails = detailsArr.length > 0 ? `(${detailsArr.join(', ')})` : '';

    // Parse tag cảnh báo
    let tagsHtml = '';
    try {
        if (p.conditions) {
            const tags = typeof p.conditions === 'string' ? JSON.parse(p.conditions) : p.conditions;
            if (Array.isArray(tags)) {
                tagsHtml = tags.map(tag => 
                    `<span style="display:inline-block; padding: 2px 6px; margin-right: 4px; margin-bottom: 4px; border-radius: 4px; background-color: #fee2e2; color: #dc2626; font-size: 10px; font-weight: 700; border: 1px solid #fecaca;">${tag}</span>`
                ).join('');
            }
        }
    } catch (e) { console.error("Parse error", e); }

    // Nút gọi điện
    const callButton = p.contact_phone 
        ? `<a href="tel:${p.contact_phone}" style="display: block; width: 100%; text-align: center; background-color: #3b82f6; color: white; padding: 8px 0; border-radius: 6px; text-decoration: none; font-weight: 600; margin-top: 12px; font-size: 13px;">📞 Gọi ngay (${p.contact_phone})</a>`
        : '';

    return `
        <div style="font-family: sans-serif; min-width: 240px; color: #1f2937;">
            <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                <div style="font-weight: 800; font-size: 15px; color: #111827;">${p.code || 'N/A'}</div>
                <div style="background-color: ${statusBg}; color: ${statusColor}; padding: 2px 8px; border-radius: 99px; font-size: 10px; font-weight: 700;">${p.status || 'Unknown'}</div>
            </div>
            ${p.name ? `<div style="font-weight: 600; font-size: 13px; margin-bottom: 4px;">👤 ${p.name}</div>` : ''}
            <div style="margin-bottom: 6px;">${tagsHtml}</div>
            <div style="font-size: 12px; color: #4b5563; margin-bottom: 6px;">📍 ${p.address || 'Chưa có địa chỉ'}</div>
            <div style="font-size: 12px; color: #4b5563;">👥 <b>${totalPeople} người</b> ${peopleDetails}</div>
            ${callButton}
            <div style="margin-top: 8px; font-size: 10px; color: #9ca3af; text-align: center;">ID: ${p.id ? String(p.id).slice(0, 8) : '...'}</div>
        </div>
    `;
};

// --- 7. Core Logic: Vẽ Marker (Diffing & Type Guard) ---
const updateMarkers = () => {
  const layer = markersLayer.value;
  const map = mapInstance.value;
  if (!layer || !map) return;

  const currentDataIds = new Set<string>();

  props.points.forEach((rawPoint) => {
    // 1. Phân loại Point vs Cluster
    // Kiểm tra xem có phải Cluster không (có total và total > 1)
    const isCluster = 'total' in rawPoint && (rawPoint.total as number) >= 1;

    let uniqueId = '';
    
    if (isCluster) {
      // Ép kiểu sang BackendPoint
      const cluster = rawPoint as BackendPoint;
      uniqueId = `cluster_${cluster.latitude}_${cluster.longitude}_${cluster.total}`;
    } else {
      // Ép kiểu sang MapPoint
      const point = rawPoint as MapPoint;
      uniqueId = point.id ? String(point.id) : `point_${point.latitude}_${point.longitude}`;
    }

    currentDataIds.add(uniqueId);

    // 2. Check tồn tại
    if (activeMarkers.has(uniqueId)) return;

    // 3. Tạo Marker
    const latlng = parseLatLng(rawPoint);
    if (!latlng) return;

    let marker: L.Marker;

    if (isCluster) {
      // === XỬ LÝ BACKEND POINT (CLUSTER) ===
      const cluster = rawPoint as BackendPoint;
      const count = cluster.total;
      const size = count < 10 ? 30 : (count < 100 ? 40 : 50);
      
      const clusterIcon = L.divIcon({
        html: `<div style="
            background-color: rgba(59, 130, 246, 0.9); /* Màu xanh Blue */
            width: ${size}px; 
            height: ${size}px;
            border-radius: 50%; /* Bo tròn thành hình tròn */
            border: 2px solid white;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-family: sans-serif;
            font-size: 14px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
          ">
            <span>${count}</span>
          </div>`,
        className: '',
        iconSize: [size, size],
        iconAnchor: [size / 2, size / 2]
      });

      marker = L.marker(latlng, { icon: clusterIcon, zIndexOffset: 500 });
      marker.on('click', () => {
        const currentZ = map.getZoom();
        map.flyTo(latlng, currentZ < 15 ? currentZ + 2 : 17, { duration: 0.5 });
      });

    } else {
      // === XỬ LÝ MAP POINT (CHI TIẾT) ===
      const point = rawPoint as MapPoint;
      
      marker = L.marker(latlng, { icon: getIcon(point.status || 'default') });
      
      // Ở đây point là MapPoint nên an toàn khi gọi các trường chi tiết
      const popupHtml = createPopupContent(point);
      marker.bindPopup(popupHtml, { minWidth: 250 });
    }

    layer.addLayer(marker);
    activeMarkers.set(uniqueId, marker);
  });

  // 4. Cleanup
  for (const [id, marker] of activeMarkers) {
    if (!currentDataIds.has(id)) {
      layer.removeLayer(marker);
      activeMarkers.delete(id);
    }
  }
};

// --- 8. Event Handlers ---
const onMapMoveEnd = () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    const map = mapInstance.value;
    if (!map) return;
    
    const currentBounds = map.getBounds();
    const currentZ = map.getZoom();

    if (lastFetchedBounds && lastFetchedBounds.contains(currentBounds) && currentZ === lastZoom) return;

    const paddedBounds = currentBounds.pad(0.2); 
    lastFetchedBounds = paddedBounds;
    lastZoom = currentZ;

    emit('fetch-new-data', {
      min_lat: paddedBounds.getSouth(),
      max_lat: paddedBounds.getNorth(),
      min_lng: paddedBounds.getWest(),
      max_lng: paddedBounds.getEast(),
      zoom: currentZ,
    });
  }, 300);
};

const onMapReady = (mapObj: L.Map) => {
  mapInstance.value = mapObj;
  markersLayer.value = L.layerGroup();
  mapInstance.value.addLayer(markersLayer.value);
  updateMarkers();
  onMapMoveEnd();
};

// --- 9. Watchers & Lifecycle ---
watch(() => props.points, updateMarkers, { deep: true });
watch(userLatLng, (newLoc) => {
  if (mapInstance.value && isValidUserLocation.value) {
    mapInstance.value.flyTo(newLoc, 14, { duration: 1.5 });
  }
});

onBeforeUnmount(() => {
  clearTimeout(debounceTimer);
  if (markersLayer.value) markersLayer.value.clearLayers();
  activeMarkers.clear();
  mapInstance.value = null;
  markersLayer.value = null;
});
</script>