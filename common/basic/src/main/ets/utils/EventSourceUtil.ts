import http from '@ohos.net.http'
import util from '@ohos.util'

/**
 * 配置 HTTP 请求的选项，包括方法、头部和请求体
 */
interface EventSourceOptions {
  method?: http.RequestMethod
  headers?: Record<string, string>
  body?: string
}

/**
 * 定义 SSE 事件的结构，包含数据和类型
 */
interface EventSourceEvent {
  data: string
  type?: string
}

/**
 * HTTP 请求的具体配置项
 */
interface RequestOptions {
  method: http.RequestMethod
  header: Record<string, string>
  readTimeout: number
  extraData?: string
}

/**
 * 定义 SSE 事件回调函数
 */
type EventCallback = (event: EventSourceEvent) => void

/**
 * SSE 订阅类
 * 使用 HarmonyOS 的 http 模块建立网络连接
 * 使用 util.TextDecoder 解码接收到的数据
 */
export class EventSource {
  private httpRequest: http.HttpRequest
  private url: string
  private options: EventSourceOptions
  private onmessage: EventCallback | null = null
  private onerror: ((error: Error) => void) | null = null
  private oncomplete: (() => void) | null = null
  private buffer: string = ''
  private isActive: boolean = false
  private decoder: util.TextDecoder = new util.TextDecoder()

  constructor(url: string, options: EventSourceOptions = {}) {
    this.url = url // 请求路径url
    this.options = options // 请求需要的参数信息
    this.httpRequest = http.createHttp() // 调用createHttp()方法，创建一个HttpRequest对象
    this.connect()
  }

  public set onMessage(callback: EventCallback) {
    this.onmessage = callback
  }

  public set onError(callback: (error: Error) => void) {
    this.onerror = callback
  }

  public set onComplete(callback: () => void) {
    this.oncomplete = callback
  }

  // 关闭请求
  public close() {
    this.isActive = false
    if (this.httpRequest) {
      // 取消订阅HTTP流式响应数据接收事件
      this.httpRequest.off('dataReceive')
      // 当该请求使用完毕时，调用destroy方法主动销毁
      this.httpRequest.destroy()
    }
  }

  // 封装请求
  private connect() {
    this.isActive = true

    const headers: Record<string, string> = {
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Content-Type': 'application/json'
    }

    if (this.options.headers) {
      // 合并headers
      headers['Content-Type'] = this.options.headers['Content-Type'] || headers['Content-Type'] || ''
      headers['Accept'] = this.options.headers['Accept'] || headers['Accept'] || ''
      headers['Cache-Control'] = this.options.headers['Cache-Control'] || headers['Cache-Control'] || ''
      headers['Connection'] = this.options.headers['Connection'] || ''
    }

    const requestOptions: RequestOptions = {
      method: this.options.method || http.RequestMethod.POST, // 请求方式
      header: headers, // 请求头信息
      readTimeout: 86400000 // 读取超时时间，设置较长以支持流式传输
    }

    // 当使用POST请求时此字段用于传递请求体内容
    if (this.options.body) {
      requestOptions.extraData = this.options.body
    }

    // 设置数据接收监听,订阅HTTP流式响应数据接收事件
    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      if (!this.isActive) {
        return
      }
      try {
        const chunk = this.decoder.decode(new Uint8Array(data))
        this.processChunk(chunk)
      } catch (e) {
        this.handleError(new Error('Failed to decode chunk'))
      }
    })

    // 发起HTTP网络请求并返回流式响应
    let promise = this.httpRequest.requestInStream(
      this.url,
      requestOptions
    )

    // 接收请求返回的数据，成功走onComplete回调，失败走handleError回调
    promise.then((data: number) => {
      if (this.oncomplete) {
        this.oncomplete()
      }
    }).catch((err: Error) => {
      this.handleError(err)
    });
  }

  // 处理返回的数据
  private processChunk(chunk: string) {
    this.buffer += chunk
    const lines = this.buffer.split('\n')
    this.buffer = lines[lines.length - 1] || ''

    for (let i = 0; i < lines.length - 1; i++) {
      const line = lines[i]
      if (line.trim() === '') {
        continue
      }
      if (line.startsWith('data:')) {
        const data = line.slice(5).trim()
        if (this.onmessage) {
          try {
            this.onmessage({ data })
          } catch (e) {
            this.handleError(new Error('Error in message handler'))
          }
        }
      }
    }
  }

  // 处理错误信息回调
  private handleError(error: Error) {
    if (this.onerror) {
      this.onerror(error)
    }
    this.close()
  }
}