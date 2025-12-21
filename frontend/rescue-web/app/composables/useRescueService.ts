// composables/useRescueService.ts
import type { RescueResponse, RescueFilter, FindTeamParams, RescueTeam, AssignTeam } from '@/types/rescue';

export const useRescueService = () => {
    // 1. Dùng Client chuẩn (đã có Auth & BaseURL)
    const { apiFetch } = useApiClient();
    const RESOURCE = '/api/requests';

    // --- Các hàm gọi API ---
    
    const getAll = async (filter: RescueFilter): Promise<RescueResponse> => {
        return await apiFetch<RescueResponse>(RESOURCE, {
            method: 'GET',
            params: filter // apiFetch tự động serialize object thành query param
        });
    };

    const updateStatus = async (id: string, status: string): Promise<void> => {
        await apiFetch(`${RESOURCE}/${id}/status`, {
            method: 'PATCH',
            body: { status }
        });
    };

    const findNearbyTeams = async (params: FindTeamParams): Promise<RescueTeam[]> => {
        return await apiFetch<RescueTeam[]>('/api/rescue-teams/find-teams', {
            method: 'GET',
            params: {
                latitude: params.latitude,
                longitude: params.longitude,
                radius_km: params.radius_km
            }
        });
    };

    const assignTeam = async (data: AssignTeam): Promise<void> => {
        return await apiFetch('/api/rescue-teams/dispatch/assign', {
            method: 'POST',
            body: {
                request_id: data.requestId,
                rescue_team_id: data.rescueTeamId
            }
        });
    };

    return {
        getAll,
        updateStatus,
        findNearbyTeams,
        assignTeam
    };
};