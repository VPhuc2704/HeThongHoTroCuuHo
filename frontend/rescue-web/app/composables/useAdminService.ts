// composables/useAdminService.ts
import type { AccountListResponse, CreateAccountPayload } from '~/types/account';
import type { ApiResponse } from '~/types/api';
import type { Rescue, UpdateTeamPayload} from '@/types/rescue';

export const useAdminService = () => {
    const { apiFetch } = useApiClient();

    // --- QUẢN LÝ TÀI KHOẢN ---
    
    // Lấy danh sách (có phân trang)
    const getAccounts = async (cursor: string | null = null, limit = 10, search = '') => {
        return await apiFetch<AccountListResponse>('/api/admin/accounts', {
            method: 'GET',
            params: { 
                cursor, // Gửi mốc thời gian lên server
                limit, 
                search 
            }
        });
    };

    // Tạo tài khoản mới (Cấp quyền)
    const createAccount = async (payload: CreateAccountPayload) => {
        return await apiFetch('/api/admin/accounts', {
            method: 'POST',
            body: payload
        });
    };

    // Khóa/Mở khóa tài khoản
    const toggleActive = async (id: number, isActive: boolean) => {
        return await apiFetch(`/api/admin/accounts/${id}/active`, {
            method: 'PATCH',
            body: { is_active: isActive }
        });
    };

    // --- QUẢN LÝ ĐỘI CỨU HỘ ---

    const getTeams = async () => {
        const res = await apiFetch<ApiResponse<Rescue[]>>('/api/rescue_team/', {
            method: 'GET'
        });

        // 2. BÓC TÁCH DỮ LIỆU (Unwrap)
        // Nếu res hoặc res.data null thì trả về mảng rỗng [] để không crash app
        return res?.data ?? [];
    };

    const updateTeam = async (id: string, payload: UpdateTeamPayload) => {
        return await apiFetch(`/api/rescue_team/${id}`, {
            method: 'PATCH',
            body: payload
        });
    };

    const deleteTeam = async (id: string) => {
        return await apiFetch(`/api/rescue-team/${id}`, { method: 'DELETE' });
    };

    return {
        getAccounts,
        createAccount,
        toggleActive,
        getTeams,
        updateTeam,
        deleteTeam
    };
};