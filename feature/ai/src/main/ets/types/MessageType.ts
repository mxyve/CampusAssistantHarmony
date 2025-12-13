/** 消息接口返回的数据结构 */
export interface MessageRecordVO {
  id: number;
  sessionId: number;
  userId: number;
  role: 'user' | 'assistant';
  content: string;
  modelName: string;
  tokens: number | null;
  hasThinking: number;
  thinkingContent: string | null;
  webSearch: number;
  status: number;
  statusDesc: string;
  createTime: string;
  updateTime: string;
}

/** 消息列表分页响应 */
export interface MessageListResponseData {
  current: number;
  size: number;
  total: number;
  pages: number;
  records: MessageRecordVO[];
}

/** 请求参数 */
export interface MessagePageDTO {
  sessionId: number;
  current?: number;
  size?: number;
}

/** 消息列表查询参数 */
export interface MessageQueryParams {
  current?: number;
  size?: number;
}