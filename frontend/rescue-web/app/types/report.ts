export interface ILocation {
  lat: number;
  lng: number;
  address?: string;
}

export interface IRescueRequest {
  phone: string;
  type: 'accident' | 'fire' | 'flood' | 'medical' | 'other';
  description: string;
  location: ILocation;
  images?: string[]; // URL ảnh
  status: 'pending' | 'processing' | 'completed';
}