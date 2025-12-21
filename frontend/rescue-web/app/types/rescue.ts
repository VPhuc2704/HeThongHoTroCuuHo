export interface RescueRequest {
    id: string;
    name: string;
    contact_phone: string;
    adults: number;
    children: number;
    elderly: number;
    people_summary: string;
    latitude: number;
    longitude: number;
    address: string;
    status: string;
    created_at: string;
    conditions: string[];
    media_urls: string[];
    description_short: string;
    active_assignment: ActiveAssignment | null;
}

export interface RescueFilter {
    page: number;
    page_size: number;
    search?: string;
    status?: string;
}

export interface RescueResponse {
    items: RescueRequest[];
    total: number;
    page: number;
    page_size: number;
}

export interface RescueTeam{
    id: string;
    name: string;
    contract_phone: string | null;
    distance: number;
}

export interface FindTeamParams{  
    latitude: number;
    longitude: number;
    radius_km: number
}

export interface AssignTeam{
    requestId: string;
    rescueTeamId: string
}

export interface ActiveAssignment {
    task_id: string;
    status: string;
    team_name: string;
    team_phone: string | null;
    team_lat: number;
    team_lng: number;
    updated_at: string;
}

export interface Rescue{
    id: string;
    name: string;
    latitude: number | null;
    longitude: number | null;
    contact_phone: string | null;
    status: string;
}

export interface UpdateTeamPayload {
    name?: string;
    latitude?: number | null;
    longitude?: number | null;
    contact_phone?: string | null;
    status?: string;
}