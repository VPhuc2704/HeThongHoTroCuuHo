import L from 'leaflet';

export const useMapIcons = () => {
  const iconCache = new Map<string, L.Icon>();

  const ICONS = {
    blue: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
    red: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
    green: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  };

  const SHADOW_URL = 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png';

  const getStatusColor = (status: string = ''): keyof typeof ICONS => {
    const s = status.toLowerCase();
    if (s.includes('chờ') || s.includes('pending')) return 'red';
    if (s.includes('xong') || s.includes('finished')) return 'green';
    return 'blue';
  };

  const getIcon = (status?: string): L.Icon => {
    const color = getStatusColor(status);
    
    if (!iconCache.has(color)) {
      iconCache.set(color, new L.Icon({
        iconUrl: ICONS[color],
        shadowUrl: SHADOW_URL,
        iconSize: [25, 41],
        iconAnchor: [12, 41],
        popupAnchor: [1, -34],
        shadowSize: [41, 41]
      }));
    }
    
    return iconCache.get(color)!;
  };

  return { getIcon };
};