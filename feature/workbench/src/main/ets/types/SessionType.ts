/** 会话分页请求参数 */
export interface SessionPageDTO {
  userId: number;
  current?: number;
  size?: number;
}

/** 单个会话记录 */
export interface SessionRecordVO {
  id: number;
  title: string;
  modelName: string;
  status: number;
  lastMessage: string | null;
  lastMessageTime: string | null;
  createTime: string;
  updateTime: string;
  isPinned: boolean;
}

export interface ApiResponse<T = any> {
  code: number;
  message: string;
  data: T;
}

// 会话列表接口返回的data结构
export interface SessionListResponseData {
  current: number;
  size: number;
  total: number;
  pages: number;
  records: SessionRecordVO[];
}

// Axios请求参数接口
export interface SessionListRequestParams {
  params: SessionPageDTO; // 明确参数结构：包含SessionPageDTO类型的params字段
}