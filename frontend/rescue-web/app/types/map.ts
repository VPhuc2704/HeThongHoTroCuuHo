export interface MapPoint {
  id: string;
  latitude: number | string;
  longitude: number | string;
  status: 'pending' | 'processing' | 'finished' | string;
}

export type LatLngTuple = [number, number];

export interface MapBounds {
  min_lat: number;
  max_lat: number;
  min_lng: number;
  max_lng: number;
  zoom: number;
}