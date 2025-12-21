import { User, FirstAidKit, Management } from '@element-plus/icons-vue'; 

type EpTagType = 'primary' | 'success' | 'warning' | 'danger' | 'info';

export const getRoleInfo = (roleName: string): { type: EpTagType; icon: any; label: string } => {
    const role = roleName?.toUpperCase() || '';

    if (role.includes('ADMIN') || role.includes('QUẢN TRỊ')) {
        return { type: 'danger', icon: Management, label: 'Quản trị viên' };
    }

    // 3. Check Đội cứu hộ
    if (role.includes('RESCUE') || role.includes('TEAM') || role.includes('CỨU HỘ')) {
        return { type: 'success', icon: FirstAidKit, label: 'Đội cứu hộ' }; 
    }

    return { type: 'info', icon: User, label: 'Người dân' };
};

export const getAvatarLetter = (email: string) => (email ? email.charAt(0).toUpperCase() : '?');