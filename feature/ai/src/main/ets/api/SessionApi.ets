import { AxiosUtil } from 'network';
import {
  SessionPageDTO, SessionListResponseData
} from '../types/SessionType';

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
}