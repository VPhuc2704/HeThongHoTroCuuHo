import L from 'leaflet';

export const useMapIcons = () => {
  // Cache để không phải tạo lại object Icon mỗi lần render
  const iconCache = new Map<string, L.Icon>();

  // 1. Thêm đầy đủ các màu có trong bộ thư viện leaflet-color-markers
  const ICONS = {
    blue: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
    red: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
    green: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
    orange: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-orange.png',
    yellow: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-gold.png',
    violet: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-violet.png',
    grey: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-grey.png',
    black: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-black.png',
  };

  const SHADOW_URL = 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png';

  // 2. Logic ánh xạ Status -> Màu icon
  const getIconColorKey = (status: string | null = ''): keyof typeof ICONS => {
    if (!status) return 'grey'; // Không có status thì trả về xám

    const s = status.toLowerCase().trim();

    // --- KHẨN CẤP: MÀU ĐỎ ---
    if (s === 'chờ xử lý' || s === 'pending') return 'red';

    // --- ĐÃ PHÂN CÔNG: MÀU CAM ---
    if (s === 'đã phân công' || s === 'assigned' || s === 'processing') return 'orange';

    // --- ĐANG THỰC HIỆN: MÀU XANH DƯƠNG ---
    if (s === 'đang thực hiện' || s === 'in_progress') return 'blue';

    // --- HOÀN THÀNH: MÀU XANH LÁ ---
    if (s === 'hoàn thành' || s === 'finished' || s === 'done') return 'green';

    // --- AN TOÀN: MÀU TÍM (Thay cho Cyan vì bộ icon này không có Cyan) ---
    if (s === 'an toàn' || s === 'safe') return 'violet';

    // --- HỦY / KHÁC: MÀU XÁM ---
    return 'grey';
  };

  const getIcon = (status?: string | null): L.Icon => {
    const colorKey = getIconColorKey(status);
    
    // Kiểm tra cache xem đã tạo icon màu này chưa
    if (!iconCache.has(colorKey)) {
      iconCache.set(colorKey, new L.Icon({
        iconUrl: ICONS[colorKey],
        shadowUrl: SHADOW_URL,
        iconSize: [25, 41],
        iconAnchor: [12, 41],
        popupAnchor: [1, -34],
        shadowSize: [41, 41]
      }));
    }
    
    return iconCache.get(colorKey)!;
  };

  return { getIcon };
};