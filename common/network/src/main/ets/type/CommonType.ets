/**
 * 基础响应接口
 */
export interface BaseResponse<T> {
  code: number;
  message: string;
  data: T;
}


/**
 * 分页响应接口
 */
export interface PageResponse<T> extends BaseResponse<T[]> {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

/**
 * 列表响应接口
 */
export interface ListResponse<T> extends BaseResponse<T[]> {
  list: T[];
  total?: number;
}


