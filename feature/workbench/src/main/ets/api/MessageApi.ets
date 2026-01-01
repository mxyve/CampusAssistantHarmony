// ScholarshipApi.ets
import http from '@ohos.net.http';
import util from '@ohos.util';
import {
  ScholarshipStreamOptions, SSEStreamController, ScholarshipStreamParams
} from '../types/ScholarshipType';

export interface MessageAttachment {
  type: 'image';
  url: string;
  name?: string;
  size?: number;
}

export class ScholarshipApi {
  private static readonly BASE_URL = 'http://192.168.0.102:6060';
  private static readonly STREAM_API = '/ai/bailian/agent/stream';

  static async streamChat(options: ScholarshipStreamOptions): Promise<SSEStreamController> {
    let httpRequest: http.HttpRequest | null = null;
    let isClosed = false;
    const decoder = new util.TextDecoder('utf-8');

    try {
      // 拼接URL（兼容token传参，对齐原有逻辑）
      const queryStr =
        `message=${encodeURIComponent(options.params.message)}${options.token ? `&token=${options.token}` : ''}`;
      const fullUrl = `${ScholarshipApi.BASE_URL}${ScholarshipApi.STREAM_API}?${queryStr}`;

      httpRequest = http.createHttp();
      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: {
          'Accept': 'text/event-stream;charset=UTF-8',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
          'Charset': 'UTF-8'
        },
        readTimeout: 60000,
        connectTimeout: 10000
      };

      // 对齐原有SSE数据处理逻辑
      httpRequest.on('dataReceive', (data: ArrayBuffer) => {
        if (isClosed) {
          return;
        }
        try {
          const chunk = decoder.decode(new Uint8Array(data));
          if (chunk) {
            options.onMessage(chunk); // 直接透传原始数据给组件处理
          }
        } catch (error) {
          options.onError?.(error as Error);
        }
      });

      httpRequest.on('dataEnd', () => {
        if (!isClosed) {
          options.onComplete();
        }
      });

      httpRequest.requestInStream(fullUrl, requestOptions)
        .then((code: number) => {
          if (code >= 400 && !isClosed) {
            options.onError?.(new Error(`请求失败，状态码: ${code}`));
          }
        })
        .catch((err: Error) => {
          if (!isClosed) {
            options.onError?.(err);
          }
        });

      return {
        close: () => {
          if (!isClosed) {
            isClosed = true;
            httpRequest?.off('dataReceive');
            httpRequest?.off('dataEnd');
            httpRequest?.destroy();
          }
        }
      };

    } catch (error) {
      options.onError?.(error as Error);
      httpRequest?.destroy();
      return {
        close: () => {
        }
      };
    }
  }
}