import { AxiosUtil } from 'network';
import {
  MessageListResponseData, MessagePageDTO, MessageQueryParams, MessageRecordVO
} from '../types/MessageType';

/** 消息相关接口 */
export class MessageApi {
  /** 查询会话消息历史 */
  static async getMessageList(params: MessagePageDTO): Promise<MessageListResponseData | null> {

    try {
      const queryParams: MessageQueryParams = {
        current: params.current || 1,
        size: params.size || 20
      };

      console.log('发送消息列表请求，参数:', params, queryParams);

      const response = await AxiosUtil.get<MessageRecordVO[]>(
        `/api/v1/messages/session/${params.sessionId}`,
        queryParams
      );

      console.log('消息API响应:', response);
      console.log('响应数据:', response.data);

      if (Array.isArray(response.data)) {
        // 将数组包装成前端期望的分页格式
        const result: MessageListResponseData = {
          current: 1,
          size: response.data.length,
          total: response.data.length,
          pages: 1,
          records: response.data
        };
        console.log('转换后的数据:', result);
        return result;
      } else {
        console.error('响应数据不是数组格式:', response.data);
        return null;
      }
    } catch (error) {
      console.error('获取消息列表异常:', error);
      return null;
    }
  }
}