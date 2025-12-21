export interface Role {
    id: number;
    name: string;
}

export interface Account {
    id: number;
    email: string;
    phone?: string;
    role: Role;
    is_active: boolean;
    created_at: string;
}

export interface CreateAccountPayload {
    email: string ;
    password: string;
    re_password?: string;
    role_code: string; 
    phone?: string;
}

export interface AccountListResponse {
  items: Account[];
  next_cursor: string | null;
}