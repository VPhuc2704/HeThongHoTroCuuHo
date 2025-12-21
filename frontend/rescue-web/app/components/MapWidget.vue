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
      
      <l-marker v-if="isValidUserLocation" :lat-lng="userLatLng">
        <l-popup>Vị trí của bạn</l-popup>
      </l-marker>
    </l-map>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed, onBeforeUnmount, type PropType } from 'vue';
import { LMap, LTileLayer, LMarker, LPopup } from '@vue-leaflet/vue-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet.markercluster/dist/MarkerCluster.css';
import 'leaflet.markercluster/dist/MarkerCluster.Default.css';
import 'leaflet.markercluster';

import type { MapPoint, LatLngTuple, MapBounds } from '~/types/map';
import { useMapIcons } from '~/composables/useMapIcons';

const props = defineProps({
  points: { type: Array as PropType<MapPoint[]>, default: () => [] },
  // Use a default value to prevent undefined errors upstream
  userLocation: { type: Array as PropType<number[]>, default: () => [0, 0] },
});

const emit = defineEmits<{
  (e: 'fetch-new-data', bounds: MapBounds): void
}>();

// --- Logic Setup ---
const { getIcon } = useMapIcons();
const currentZoom = ref(13);
const mapOptions = { zoomControl: true, attributionControl: true, minZoom: 2, maxZoom: 19 };

let mapInstance: L.Map | null = null;
let markersLayer: L.MarkerClusterGroup | null = null;
let debounceTimer: ReturnType<typeof setTimeout>;

// --- Computed ---
const isValidUserLocation = computed(() => 
  props.userLocation?.length === 2 && props.userLocation[0] !== 0
);

// FIX: Added '!' or '?? 0' to satisfy TypeScript strict array access
const userLatLng = computed((): LatLngTuple => 
  isValidUserLocation.value 
    ? [props.userLocation[0]!, props.userLocation[1]!] 
    : [0, 0]
);

const mapCenter = computed((): LatLngTuple => 
  isValidUserLocation.value ? userLatLng.value : [10.7769, 106.7009]
);

// --- Methods ---
const parseLatLng = (p: MapPoint): LatLngTuple | null => {
  const lat = typeof p.latitude === 'string' ? parseFloat(p.latitude) : p.latitude;
  const lng = typeof p.longitude === 'string' ? parseFloat(p.longitude) : p.longitude;
  return (isNaN(lat) || isNaN(lng)) ? null : [lat, lng];
};

const drawMarkers = () => {
  if (!mapInstance || !markersLayer) return;

  markersLayer.clearLayers();
  
  const markers = props.points
    .map(p => {
      const latlng = parseLatLng(p);
      if (!latlng) return null;

      const marker = L.marker(latlng, { icon: getIcon(p.status) });
      
      marker.bindPopup(`
        <div class="text-center">
          <strong>ID: ${String(p.id).slice(0, 8)}</strong><br>
          <span class="capitalize">${p.status || 'Unknown'}</span>
        </div>
      `);
      
      return marker;
    })
    .filter((m): m is L.Marker => m !== null);

  markersLayer.addLayers(markers);
};

const onMapMoveEnd = () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    if (!mapInstance) return;
    
    const bounds = mapInstance.getBounds();
    emit('fetch-new-data', {
      min_lat: bounds.getSouth(),
      max_lat: bounds.getNorth(),
      min_lng: bounds.getWest(),
      max_lng: bounds.getEast(),
      zoom: mapInstance.getZoom(),
    });
  }, 400);
};

const onMapReady = (mapObj: L.Map) => {
  mapInstance = mapObj;
  
  markersLayer = L.markerClusterGroup({
    disableClusteringAtZoom: 18,
    maxClusterRadius: 60,
    chunkedLoading: true
  });
  
  mapInstance.addLayer(markersLayer);
  drawMarkers();
};

// --- Watchers & Lifecycle ---
watch(() => props.points, drawMarkers);

watch(userLatLng, (newLoc) => {
  if (mapInstance && isValidUserLocation.value) {
    mapInstance.setView(newLoc, 14);
  }
});

onBeforeUnmount(() => {
  clearTimeout(debounceTimer);
  if (markersLayer) markersLayer.clearLayers();
});
</script>