// types/task.ts
export interface RescueRequest {
  code: string;
  name: string;
  contact_phone: string;
  adults: number;
  children: number;
  elderly: number;
  address: string;
  latitude: number;
  longitude: number;
  conditions: string[];
  description: string;
}

export interface RescueTeam {
  team_id: string;
  team_name: string;
  team_latitude: number;
  team_longitude: number;
  team_phone: string;
}

export interface RescueTask {
  id: string;
  status: string;
  assigned_at: string;
  rescue_request: RescueRequest;
  rescue_team: RescueTeam;
}