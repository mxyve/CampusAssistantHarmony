// ==========  新增：AgentType 相关接口（替代 ScholarshipType）  ==========// 1. Agent 消息项类型（替代 ScholarshipMessageItem）
export interface AgentMessageItem {
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

// 2. Agent 流式请求参数（确保包含 sessionId/modelName/content，解决缺失字段报错）
export interface AgentStreamParams {
  message: string;
  sessionId: number; // 补全：解决缺失字段报错
  modelName: string; // 补全：解决缺失字段报错
  content: string; // 补全：解决缺失字段报错
}

// 3. Agent 流式请求配置（替代 ScholarshipStreamOptions）
export interface AgentStreamOptions {
  token?: string;
  params: AgentStreamParams;
  onMessage: (data: string) => void;
  onError?: (error: Error) => void;
  onComplete: () => void;
}

// 4. SSE 控制器类型（复用原有，若 AgentApi 已定义可直接导入）
export type SSEStreamController = {
  close: () => void;
};

// 组件属性接口（不变，仅替换消息项类型）
interface AgentChatComponentProps {
  sessionId: number;
  initialMessages: AgentMessageItem[]; // 改用 AgentMessageItem
  userId: number;
  isLoggedIn: boolean;
}