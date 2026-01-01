import { AxiosUtil } from 'network';
import {
  SessionPageDTO, SessionListResponseData
} from '../types/SessionType';

// ========== 新增：Axios 请求配置类型（匹配 AxiosUtil 的配置格式） ==========
export interface AxiosRequestConfig {
  params?: GenerateSessionTitleParams; // URL查询参数
  headers?: Record<string, string>; // 请求头
}

// 创建会话的请求参数类型
export interface CreateSessionParams {
  title: string;
  modelName: string;
  agentType?: string;
}

export interface SessionData {
  id: number;
  title: string;
  modelName: string;
  status: number;
  lastMessage: string | null;
  lastMessageTime: string | null;
  createTime: string;
  updateTime: string;
}

export interface UpdateSessionTitleParams {
  title: string; // 新的会话标题
}

// 自动生成标题的参数类型
export interface GenerateSessionTitleParams {
  userFirstMessage: string; // 用户第一条提问内容
}

/** AI会话相关接口 */
export class SessionApi {
  /** 分页获取用户会话列表 */
  static async getSessionList(params: SessionPageDTO): Promise<SessionListResponseData | null> {
    try {
      const response = await AxiosUtil.get<SessionListResponseData>('/api/v1/session', params);
      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`获取会话列表失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('获取会话列表异常:', error);
      return null;
    }
  }

  static async createSession(params: CreateSessionParams): Promise<SessionData | null> {
    try {
      const response = await AxiosUtil.post<SessionData>(
        '/api/v1/session',
        params
      );
      console.log('创建会话响应:', response);
      console.log('response.data:', JSON.stringify(response.data));
      console.log('response.data.data:', JSON.stringify(response.data.data));
      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`创建会话失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('创建会话异常:', error);
      return null;
    }
  }

  // 删除功能
  static async deleteSession(sessionId: number): Promise<boolean> {
    try {
      const response = await AxiosUtil.delete<void>(`/api/v1/session/${sessionId}`);
      return response.data.code === 200;
    } catch (error) {
      console.error('删除会话异常:', error);
      return false;
    }
  }

  static async updateSessionTitle(sessionId: number, params: UpdateSessionTitleParams): Promise<SessionData | null> {
    try {
      const response = await AxiosUtil.put<SessionData>(
        `/api/v1/session/${sessionId}/title`,
        params
      );
      console.log('修改会话标题响应:', response);
      console.log('response.data:', JSON.stringify(response.data));
      console.log('response.data.data:', JSON.stringify(response.data.data));
      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`修改会话标题失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('修改会话标题异常:', error);
      return null;
    }
  }

  /**
   * 自动生成会话标题（根据用户第一条消息）
   * @param sessionId 会话ID
   * @param params 包含用户第一条消息的参数
   * @returns 更新后的会话信息
   */
  static async generateSessionTitle(
    sessionId: number,
    params: GenerateSessionTitleParams
  ): Promise<SessionData | null> {
    try {
      // 方案1：如果 AxiosUtil.post 只支持 2 个参数（url + data），将 query 参数拼接到 URL 上
      // 核心修复：避免传第3个参数，直接拼接 query 参数到URL
      const url =
        `/api/v1/session/${sessionId}/auto-title?userFirstMessage=${encodeURIComponent(params.userFirstMessage)}`;

      // 调用 POST 请求，请求体为空对象（声明类型，解决未类型化字面量问题）
      const emptyData: Record<string, never> = {};
      const response = await AxiosUtil.post<SessionData>(url, emptyData);

      console.log('自动生成会话标题响应:', response);
      console.log('response.data:', JSON.stringify(response.data));
      console.log('response.data.data:', JSON.stringify(response.data.data));

      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`自动生成标题失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('自动生成会话标题异常:', error);
      return null;
    }
  }
}