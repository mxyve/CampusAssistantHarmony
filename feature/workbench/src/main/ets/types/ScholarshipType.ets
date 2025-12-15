// ScholarshipType.ets
export interface ScholarshipMessageItem {
  id: number;
  sessionId: number;
  userId: number;
  role: 'user' | 'assistant';
  content: string;
  modelName: string;
  status: number;
  statusDesc: string;
  createTime: string;
}

export interface ScholarshipStreamParams {
  message: string;
}

export interface ScholarshipStreamOptions {
  token?: string; // 新增token（对齐原有逻辑）
  params: ScholarshipStreamParams;
  onMessage: (data: string) => void;
  onError?: (error: Error) => void;
  onComplete: () => void;
}

export interface SSEStreamController {
  close: () => void;
}