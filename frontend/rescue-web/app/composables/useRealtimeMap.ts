import { ref, shallowRef, onMounted, onBeforeUnmount } from 'vue';
import type { MapPoint, MapBounds } from '~/types/map';

export const useRealtimeMap = () => {
  // 1. DEPENDENCY INJECTION
  // Dùng client chuẩn để kế thừa tính năng tự động gửi Token & Refresh Token
  const { apiFetch } = useApiClient(); 
  
  // Lấy cấu hình URL từ nuxt.config.ts (Không hardcode IP/Port)
  const config = useRuntimeConfig();
  const API_BASE = config.public.apiBase as string; 

  // 2. STATE
  // Dùng shallowRef để tối ưu hiệu năng khi array lớn (Vue không theo dõi sâu từng phần tử)
  const points = shallowRef<MapPoint[]>([]);
  const socketStatus = ref<'CONNECTING' | 'OPEN' | 'CLOSED'>('CLOSED');
  let socket: WebSocket | null = null;

  // 3. HTTP FETCH LOGIC
  const fetchPoints = async (bounds?: MapBounds) => {
    try {
      // CLEAN CODE: 
      // - Dùng apiFetch thay vì $fetch
      // - Dùng params object thay vì nối chuỗi thủ công (an toàn & dễ đọc)
      const res = await apiFetch<MapPoint[]>('/api/map-points', {
        params: {
          min_lat: bounds?.min_lat ?? 8.0,
          max_lat: bounds?.max_lat ?? 12.0,
          min_lng: bounds?.min_lng ?? 104.0,
          max_lng: bounds?.max_lng ?? 108.0,
          zoom: bounds?.zoom ?? 10
        }
      });

      if (Array.isArray(res)) {
        points.value = res;
      }
    } catch (error) {
      // Lỗi 401 đã được apiFetch xử lý ngầm, ta chỉ log lỗi khác
      console.error('Failed to fetch map points:', error);
    }
  };

  // 4. WEBSOCKET LOGIC
  const connectWebSocket = () => {
    if (!API_BASE) return;
    
    socketStatus.value = 'CONNECTING';

    // Tự động chuyển đổi http/https sang ws/wss
    // Ví dụ: http://localhost:8000 -> ws://localhost:8000
    const wsProtocol = API_BASE.startsWith('https') ? 'wss' : 'ws';
    const wsUrl = API_BASE.replace(/^https?/, wsProtocol) + '/ws/map/';

    socket = new WebSocket(wsUrl);

    socket.onopen = () => {
      console.log('🟢 WS Connected');
      socketStatus.value = 'OPEN';
    };

    socket.onclose = () => {
      console.warn('🔴 WS Disconnected');
      socketStatus.value = 'CLOSED';
      // Có thể thêm logic reconnect sau 5s tại đây nếu cần
    };

    socket.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        handleSocketMessage(data);
      } catch (e) {
        console.error('WS Parse Error', e);
      }
    };
  };

  // Helper: Merge dữ liệu Realtime vào mảng hiện có (Immutability)
  const handleSocketMessage = (data: MapPoint | MapPoint[]) => {
    if (Array.isArray(data)) {
      points.value = data;
      return;
    }

    // Copy-on-write để shallowRef nhận biết sự thay đổi
    const newPoints = [...points.value];
    const index = newPoints.findIndex(p => p.id === data.id);

    if (index !== -1) {
      // Cập nhật điểm cũ
      newPoints[index] = data;
    } else {
      // Thêm điểm mới
      newPoints.push(data);
    }

    points.value = newPoints;
  };

  // 5. LIFECYCLE
  onMounted(() => {
    // Chỉ kết nối socket, KHÔNG gọi fetchPoints() ở đây
    // Để MapWidget tự gọi khi bản đồ load xong (tránh load 2 lần gây loop)
    connectWebSocket();
  });
  
  onBeforeUnmount(() => {
    if (socket) {
      socket.close();
      socket = null;
    }
  });

  return {
    points,
    socketStatus,
    fetchPoints
  };
};