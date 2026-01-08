// composables/useRealtimeMap.ts
import { ref, shallowRef, onMounted, onBeforeUnmount, watch } from 'vue';
import type { MapPoint, MapBounds, BackendPoint } from '~/types/map';

export const useRealtimeMap = () => {
  const config = useRuntimeConfig();
  const { apiFetch } = useApiClient();
  const tokenCookie = useCookie('access_token');

  const points = shallowRef<BackendPoint[]>([]);
  const socketStatus = ref<'CONNECTING' | 'OPEN' | 'CLOSED'>('CLOSED');
  
  let socket: WebSocket | null = null;
  let reconnectTimer: NodeJS.Timeout | null = null;

  // ... (giữ nguyên hàm fetchPoints) ...
  const fetchPoints = async (bounds?: MapBounds) => {
    try {
      const res = await apiFetch<BackendPoint[]>('/requests/map-points', {
        params: {
          min_lat: bounds?.min_lat ?? 8.0,
          max_lat: bounds?.max_lat ?? 12.0,
          min_lng: bounds?.min_lng ?? 104.0,
          max_lng: bounds?.max_lng ?? 108.0,
          zoom: bounds?.zoom ?? 10
        }
      });
      if (Array.isArray(res)) points.value = res;
    } catch (error) {
      console.error('Fetch error:', error);
    }
  };

  // --- LOGIC WEBSOCKET - DYNAMIC BASED ON ENVIRONMENT ---
  const connectWebSocket = () => {
    if (!tokenCookie.value) {
      console.warn('⚠️ WS: Missing Token');
      return;
    }

    if (socket?.readyState === WebSocket.OPEN || socket?.readyState === WebSocket.CONNECTING) return;
    
    socketStatus.value = 'CONNECTING';

    try {
      let wsUrl: string;

      if (typeof window === 'undefined') return; // SSR guard

      const wsBase = config.public.wsBase as string;
      const env = config.public.env as string;

      // 🔧 DETERMINE WEBSOCKET URL
      if (wsBase && (wsBase.startsWith('ws://') || wsBase.startsWith('wss://'))) {
        // Production: Use config URL
        wsUrl = `${wsBase}/ws/map/?token=${tokenCookie.value}`;
      } else {
        // Development: Use current location or default
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const host = window.location.host; // e.g., localhost:3000 or example.com
        
        // ⚠️ IMPORTANT: WebSocket must point to backend port directly
        // For development, override to backend port (8000)
        const backendHost = env === 'development' 
          ? '127.0.0.1:8000' 
          : window.location.host;
          
        wsUrl = `${protocol}//${backendHost}/ws/map/?token=${tokenCookie.value}`;
      }

      console.log('🔗 WS Target:', wsUrl);
      socket = new WebSocket(wsUrl);

      socket.onopen = () => {
        console.log('🟢 WS Connected');
        socketStatus.value = 'OPEN';
        if (reconnectTimer) clearTimeout(reconnectTimer);
      };

      socket.onclose = (event) => {
        console.warn(`🔴 WS Closed: ${event.code}`);
        socketStatus.value = 'CLOSED';
        socket = null;
        if (event.code !== 1000) reconnectTimer = setTimeout(connectWebSocket, 5000);
      };

      socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          handleSocketMessage(data);
        } catch (e) { console.error('WS JSON Error', e); }
      };

      socket.onerror = (error) => {
        console.error('🔥 WS Error:', error);
        socketStatus.value = 'CLOSED';
      };

    } catch (err) {
      console.error('🔥 WS Connection Failed:', err);
      socketStatus.value = 'CLOSED';
    }
  };

  // ... (Giữ nguyên handleSocketMessage, watch, onMounted, onBeforeUnmount) ...
  const handleSocketMessage = (data: any) => { /* ...code cũ... */ };
  
  watch(tokenCookie, (newToken) => { if(newToken) { socket?.close(); connectWebSocket(); } });
  
  onMounted(() => { if (tokenCookie.value) connectWebSocket(); });
  
  onBeforeUnmount(() => { 
    if (reconnectTimer) clearTimeout(reconnectTimer);
    socket?.close(1000); 
  });

  return { points, socketStatus, fetchPoints };
};