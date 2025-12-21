export interface ApiResponse<T> {
    success: boolean;
    code: number;
    message: string;
    data: T;     // Dữ liệu thật nằm ở đây
    details: any;
}