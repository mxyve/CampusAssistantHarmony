// ScholarshipChatComponent.ets
import { ScholarshipApi } from '../api/MessageApi';
import { MessageBubble } from './MessageBubble';
import {
  ScholarshipMessageItem, ScholarshipStreamOptions, SSEStreamController
} from '../types/ScholarshipType';
import { storageUtil } from 'storage'; // 新增token获取
import promptAction from '@ohos.promptAction';

interface ScholarshipChatComponentProps {
  sessionId: number;
  initialMessages: ScholarshipMessageItem[];
  userId: number;
  isLoggedIn: boolean; // 新增登录状态校验（对齐原有逻辑）
}

@Component
export struct ScholarshipChatComponent {
  @Prop sessionId: number;
  @Prop initialMessages: ScholarshipMessageItem[];
  @Prop userId: number;
  @Prop isLoggedIn: boolean; // 新增登录状态
  @State messageList: ScholarshipMessageItem[] = [];
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State currentAssistantMessage: ScholarshipMessageItem | null = null;
  private streamController: SSEStreamController | null = null;

  aboutToAppear() {
    this.messageList = [...this.initialMessages];
  }

  build() {
    Column() {
      // 1. 消息列表区域（完全对齐原有写法）
      Scroll() {
        Column({ space: 16 }) {
          ForEach(this.messageList, (item: ScholarshipMessageItem) => {
            MessageBubble({
              content: item.content,
              isUser: item.role === 'user',
              time: this.formatTime(item.createTime),
              statusDesc: item.statusDesc,
              userAvatar: $r('app.media.avatar_img'),
              aiAvatar: $r('app.media.avatar_img'),
              isAssistant: item.role === 'assistant' // 补充isAssistant属性
            })
          })

          if (this.currentAssistantMessage) {
            MessageBubble({
              content: this.currentAssistantMessage.content,
              isUser: false,
              time: '',
              statusDesc: this.currentAssistantMessage.statusDesc,
              aiAvatar: $r('app.media.avatar_img'),
              isAssistant: true // 补充isAssistant属性
            })
          }
        }
        .padding(16)
        .width('100%')
      }
      .layoutWeight(1)

      // 2. 输入框区域（对齐原有写法）
      this.buildInputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  buildInputArea() {
    Row({ space: 8 }) {
      TextInput({
        text: this.inputText,
        placeholder: '请输入奖助相关问题（如：国家奖学金申请条件）'
      })
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderColor('#E5E6EB')
        .borderWidth(1)
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .height(40)
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          if (this.inputText.trim() && !this.isSending && this.isLoggedIn) {
            this.sendMessage();
          }
        })

      Button(this.isSending ? '发送中...' : '发送')
        .fontSize(14)
        .backgroundColor(this.isSending ? '#A0CFFF' : '#337EFF')
        .fontColor('#FFFFFF')
        .borderRadius(20)
        .width(80)
        .height(40)
        .enabled(!this.isSending && !!this.inputText.trim() && this.isLoggedIn) // 增加登录状态校验
        .onClick(() => {
          if (this.isLoggedIn) {
            this.sendMessage();
          } else {
            promptAction.showToast({ message: '请先登录后再发送消息' });
          }
        })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderColor('#E5E6EB')
    .borderWidth({ top: 1 }) // 补充顶部边框（对齐原有样式）
  }

  // 核心：发送消息（完全对齐StreamChatComponent的sendMessage逻辑）
  private async sendMessage() {
    const userMessage = this.inputText.trim();
    if (!userMessage || this.isSending || !this.isLoggedIn) {
      return;
    }

    // 1. 获取Token（对齐原有逻辑）
    let token = '';
    try {
      const storageToken = await storageUtil.get('token');
      token = storageToken ? storageToken.toString() : '';
    } catch (error) {
      console.error('获取Token失败:', error);
      promptAction.showToast({ message: '获取登录信息失败' });
      return;
    }

    // 2. 清空输入框+标记发送中
    this.inputText = '';
    this.isSending = true;

    // 3. 构建用户消息
    const userMsg: ScholarshipMessageItem = {
      id: Date.now(),
      sessionId: this.sessionId,
      userId: this.userId,
      role: 'user',
      content: userMessage,
      modelName: 'bailian-agent',
      status: 1,
      statusDesc: '成功',
      createTime: new Date().toISOString()
    };

    // 4. 构建AI初始消息
    const assistantMsg: ScholarshipMessageItem = {
      id: Date.now() + 1,
      sessionId: this.sessionId,
      userId: 0,
      role: 'assistant',
      content: '',
      modelName: 'bailian-agent',
      status: 0,
      statusDesc: '思考中...',
      createTime: new Date().toISOString()
    };

    this.messageList = [...this.messageList, userMsg];
    this.currentAssistantMessage = assistantMsg;

    try {
      // 关闭旧连接
      this.streamController?.close();
      this.streamController = null;
      let accumulatedContent = '';

      // 5. 构建流式请求配置（对齐原有SSE处理逻辑）
      const streamOptions: ScholarshipStreamOptions = {
        token: token, // 传递token
        params: { message: userMessage },
        onMessage: (data: string) => {
          // 核心：复用原有data:前缀处理逻辑
          const lines = data.split('\n');
          for (const line of lines) {
            const trimmedLine = line.trim();
            if (!trimmedLine) {
              continue;
            }

            if (trimmedLine.startsWith('data:')) {
              const content = trimmedLine.substring(5).trim();
              if (content === '[DONE]') {
                this.handleStreamEnd(accumulatedContent, true);
                return;
              }
              if (content) {
                accumulatedContent += content;
                this.updateAssistantMessage(accumulatedContent, '回复中...');
              }
            } else {
              accumulatedContent += trimmedLine;
              this.updateAssistantMessage(accumulatedContent, '回复中...');
            }
          }
        },
        onError: (error: Error) => {
          console.error('流式请求失败:', error);
          const msg = error.message.includes('Token') ? '登录已过期，请重新登录' : `请求失败: ${error.message}`;
          promptAction.showToast({ message: msg });
          this.handleStreamEnd(msg, false);
        },
        onComplete: () => {
          this.handleStreamEnd(accumulatedContent || '暂无相关回复', true);
        }
      };

      // 6. 发起流式请求
      this.streamController = await ScholarshipApi.streamChat(streamOptions);
      if (!this.streamController) {
        throw new Error('无法创建流式连接');
      }

      // 7. 超时检测（30秒）
      setTimeout(() => {
        if (this.isSending && accumulatedContent === '') {
          this.handleStreamEnd('请求超时，请重试', false);
        }
      }, 30000);

    } catch (error) {
      console.error('发送消息异常:', error);
      this.handleStreamEnd(`发送失败: ${(error as Error).message}`, false);
    }
  }

  // 更新AI回复内容（对齐原有写法）
  private updateAssistantMessage(content: string, statusDesc: string) {
    if (this.currentAssistantMessage) {
      this.currentAssistantMessage = {
        id: this.currentAssistantMessage.id,
        sessionId: this.currentAssistantMessage.sessionId,
        userId: this.currentAssistantMessage.userId,
        role: this.currentAssistantMessage.role,
        content: content,
        modelName: this.currentAssistantMessage.modelName,
        status: this.currentAssistantMessage.status,
        statusDesc: statusDesc,
        createTime: this.currentAssistantMessage.createTime
      };
    }
  }

  // 流式结束处理（对齐原有写法）
  private handleStreamEnd(content: string, success: boolean) {
    if (this.currentAssistantMessage) {
      const completedMsg: ScholarshipMessageItem = {
        id: this.currentAssistantMessage.id,
        sessionId: this.currentAssistantMessage.sessionId,
        userId: this.currentAssistantMessage.userId,
        role: this.currentAssistantMessage.role,
        content: content,
        modelName: this.currentAssistantMessage.modelName,
        status: success ? 1 : 2,
        statusDesc: success ? '成功' : '失败',
        createTime: new Date().toISOString()
      };
      this.messageList = [...this.messageList, completedMsg];
      this.currentAssistantMessage = null;
    }

    this.streamController?.close();
    this.streamController = null;
    this.isSending = false;
  }

  // 格式化时间（完全复用原有方法）
  private formatTime(timeStr: string): string {
    if (!timeStr) {
      return '';
    }
    try {
      const date = new Date(timeStr);
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    } catch (e) {
      return '';
    }
  }

  // 组件销毁关闭连接（对齐原有写法）
  aboutToDisappear() {
    this.streamController?.close();
  }
}