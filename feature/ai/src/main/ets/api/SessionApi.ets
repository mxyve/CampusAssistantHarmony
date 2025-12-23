import { AxiosUtil } from 'network';
import {
  SessionPageDTO, SessionListResponseData
} from '../types/SessionType';

// 创建会话的请求参数类型
export interface CreateSessionParams {
  title: string;
  modelName: string;
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

/** AI会话相关接口 */
export class SessionApi {
  /** 分页获取用户会话列表 */
  static async getSessionList(params: SessionPageDTO): Promise<SessionListResponseData | null> {
    try {
      // 这里的 T 应该是 SessionListResponseData
      const response = await AxiosUtil.get<SessionListResponseData>('/api/v1/session', params);

      // response.data 是 BaseResponse<SessionListResponseData>
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
      // 这里的 T 直接传 SessionData
      const response = await AxiosUtil.post<SessionData>(
        '/api/v1/session',
        params
      );

      console.log('创建会话响应:', response);
      console.log('response.data:', JSON.stringify(response.data));
      console.log('response.data.data:', JSON.stringify(response.data.data)); // 这里应该是 SessionData

      if (response.data.code === 200) {
        return response.data.data; // 返回 SessionData
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
      // 拼接路径：/api/v1/session/{sessionId}
      const response = await AxiosUtil.delete<void>(`/api/v1/session/${sessionId}`);
      // 后端返回 code=200 则表示成功
      return response.data.code === 200;
    } catch (error) {
      console.error('删除会话异常:', error);
      return false;
    }
  }

  static async updateSessionTitle(sessionId: number, params: UpdateSessionTitleParams): Promise<SessionData | null> {
    try {
      // 后端接口路径：/api/v1/session/{sessionId}/title（PATCH请求）
      const response = await AxiosUtil.put<SessionData>(
        `/api/v1/session/${sessionId}/title`,
        params
      );

      console.log('修改会话标题响应:', response);
      console.log('response.data:', JSON.stringify(response.data));
      console.log('response.data.data:', JSON.stringify(response.data.data));

      if (response.data.code === 200) {
        return response.data.data; // 返回修改后的会话完整信息
      } else {
        console.error(`修改会话标题失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('修改会话标题异常:', error);
      return null;
    }
  }
}