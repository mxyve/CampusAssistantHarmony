import { AxiosUtil } from 'network';
import http from '@ohos.net.http'; // 导入鸿蒙http模块
import util from '@ohos.util'; // 导入工具模块
import { storageUtil } from 'storage';
import {
  MessageListResponseData, MessagePageDTO, MessageQueryParams, MessageRecordVO
} from '../types/MessageType';

/** 流式参数定义 */
export interface StreamChatParams {
  sessionId: number;
  modelName: string;
  content: string;
}

export interface StreamChatOptions {
  params: StreamChatParams;
  onMessage: (data: string) => void;
  onError?: (error: Error) => void;
  onComplete: () => void;
  token?: string;
}

// SSE流控制接口
export interface SSEStreamController {
  close: () => void;
}

/** 消息相关接口 */
export class MessageApi {
  // 仅在这定义一次baseURL
  private static readonly BASE_URL = 'http://10.20.50.197:6060';
  private static readonly STREAM_API_PATH = '/api/v1/messages/stream';

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

  /** 使用鸿蒙 http 模块实现流式聊天请求 */
  // MessageApi.ts - 修改流式请求方法
  static async streamChat(options: StreamChatOptions): Promise<SSEStreamController> {
    let httpRequest: http.HttpRequest | null = null;
    let isClosed = false;
    const decoder = new util.TextDecoder('utf-8');

    try {
      // 1. 获取Token
      let token = options.token;
      if (!token) {
        try {
          const storageToken = await storageUtil.get('token');
          token = storageToken ? storageToken.toString() : '';
          console.log('从storage获取的token:', token ? `长度:${token.length}` : '空');
        } catch (error) {
          console.warn('获取Token失败:', error);
        }
      }

      if (!token) {
        throw new Error('未获取到授权Token，请先登录');
      }

      // 2. 构造请求体
      const requestBody = JSON.stringify(options.params);
      const fullStreamUrl = `${MessageApi.BASE_URL}${MessageApi.STREAM_API_PATH}`;

      console.log('SSE请求URL:', fullStreamUrl);
      console.log('请求体:', requestBody);
      console.log('Token长度:', token.length);

      // 3. 创建HTTP请求
      httpRequest = http.createHttp();
      let buffer = '';

      // 4. 设置请求选项 - 使用流式请求
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive'
        },
        extraData: requestBody,
        readTimeout: 30000, // 30秒读取超时
        connectTimeout: 10000 // 10秒连接超时
      };

      // 5. 订阅数据接收事件 - 使用 dataReceive
      httpRequest.on('dataReceive', (data: ArrayBuffer) => {
        if (isClosed) {
          return;
        }

        try {
          const chunk = decoder.decode(new Uint8Array(data), { stream: false });
          console.log('收到数据块，长度:', chunk.length);
          console.log('原始数据:', chunk.substring(0, Math.min(100, chunk.length)) + (chunk.length > 100 ? '...' : ''));

          // 直接发送整个数据块
          if (chunk && !isClosed) {
            console.log('发送数据到回调，长度:', chunk.length);
            options.onMessage(chunk);
          }
        } catch (error) {
          if (!isClosed) {
            console.error('处理SSE数据时出错:', error);
          }
        }
      });

      // 6. 订阅请求完成事件
      httpRequest.on('dataEnd', () => {
        if (!isClosed) {
          console.log('SSE流读取完成');
          options.onComplete();
        }
      });

      // 7. 使用 requestInStream 发起流式请求
      console.log('开始发起流式请求...');
      const promise = httpRequest.requestInStream(fullStreamUrl, requestOptions);

      promise.then((responseCode: number) => {
        console.log('SSE流式请求成功，响应码:', responseCode);

        if (responseCode >= 400 && !isClosed) {
          const errorMsg = `HTTP ${responseCode}`;
          console.error('SSE响应错误:', errorMsg);
          options.onError?.(new Error(errorMsg));
        }
      }).catch((error: Error) => {
        if (!isClosed) {
          console.error('SSE请求失败:', error);
          options.onError?.(error);
        }
      });

      // 8. 返回控制器
      return {
        close: () => {
          if (!isClosed) {
            isClosed = true;
            console.log('关闭SSE流');
            if (httpRequest) {
              try {
                httpRequest.off('dataReceive');
                httpRequest.off('dataEnd');
                httpRequest.destroy();
              } catch (error) {
                console.error('关闭HTTP请求时出错:', error);
              }
            }
          }
        }
      };

    } catch (error) {
      console.error('创建SSE流失败:', error);
      options.onError?.(error instanceof Error ? error : new Error(String(error)));

      // 清理资源
      if (httpRequest) {
        try {
          httpRequest.destroy();
        } catch (e) {
          // 忽略错误
        }
      }

      // 返回一个空的控制器
      return {
        close: () => {
          if (!isClosed) {
            isClosed = true;
            console.log('关闭已出错的SSE流');
          }
        }
      };
    }
  }
}