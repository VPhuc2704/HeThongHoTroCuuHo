// types/map.ts

// 1. Dùng cho điểm chi tiết (Single Point)
export interface MapPoint {
  id: string;
  code: string | null;
  latitude: number | string;
  longitude: number | string;
  status: 'pending' | 'processing' | 'finished' | string;

  // Các trường chi tiết
  name: string | null;
  address: string | null;
  contact_phone: string | null;
  adults: number | null;
  children: number | null;
  elderly: number | null;
  conditions: string | null;

  // MapPoint có thể có total = 1 hoặc undefined
  total?: number; 
}

// 2. Dùng cho cụm (Cluster)
export interface BackendPoint {
  latitude: number | string;
  longitude: number | string;
  total: number; // Bắt buộc phải có total > 1
  // Cluster không có id, code, status...
}

// 3. Type chung cho mảng props (Quan trọng)
export type MapItem = MapPoint | BackendPoint;

export interface MapBounds {
  min_lat: number;
  max_lat: number;
  min_lng: number;
  max_lng: number;
  zoom: number;
}