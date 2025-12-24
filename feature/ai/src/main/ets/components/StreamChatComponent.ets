import { MessageApi, StreamChatOptions, SSEStreamController } from '../api/MessageApi';
import { MessageBubble } from '../components/MessageBubble';
import { storageUtil } from 'storage';
import promptAction from '@ohos.promptAction';
import { GenerateSessionTitleParams, SessionApi } from '../api/SessionApi';

// 对外暴露的属性
interface StreamChatComponentProps {
  sessionId: number; // 会话ID
  initialMessages: MessageItem[]; // 初始历史消息
  userId: number; // 当前用户ID
  isLoggedIn: boolean; // 登录状态
  onSendMessage: (message: string) => Promise<void>; // 消息发送回调
}

// 消息项类型（和原页面保持一致）
export interface MessageItem {
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

export interface SendMessageEvent {
  action: 'sendFirstMessage'; // 固定值类型
  sessionId: number;
  message: string;
}

@Component
export struct StreamChatComponent {
  @Prop sessionId: number;
  @Prop initialMessages: MessageItem[];
  @Prop userId: number;
  @Prop isLoggedIn: boolean;
  @State messageList: MessageItem[] = [];
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State currentAssistantMessage: MessageItem | null = null;
  private streamController: SSEStreamController | null = null;
  @State isNewSession: boolean = false;
  @State hasGeneratedTitle: boolean = false;

  // 组件初始化：同步初始历史消息
  aboutToAppear() {
    this.messageList = [...this.initialMessages];
    this.isNewSession = this.initialMessages.length === 0;
    console.log(`🔍会话${this.sessionId}是否为新建:`, this.isNewSession);
  }

  build() {
    Column() {
      // 消息列表
      Scroll() {
        Column({ space: 16 }) {
          ForEach(this.messageList, (item: MessageItem) => {
            MessageBubble({
              content: item.content,
              isUser: item.role === 'user',
              time: this.formatTime(item.createTime),
              statusDesc: item.statusDesc,
              isAssistant: item.role === 'assistant',
              userAvatar: $r('app.media.avatar_img'),
              aiAvatar: $r('app.media.robot')
            })
          })

          // 正在回复的AI消息
          if (this.currentAssistantMessage) {
            MessageBubble({
              content: this.currentAssistantMessage.content,
              isUser: false,
              time: '',
              statusDesc: this.currentAssistantMessage.statusDesc,
              isAssistant: true,
              userAvatar: $r('app.media.avatar_img'),
              aiAvatar: $r('app.media.robot')
            })
          }
        }
        .padding(16)
        .width('100%')
      }
      .layoutWeight(1)

      // 输入框区域（封装到组件内，也可暴露为slot）
      this.buildInputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  buildInputArea() {
    Row({ space: 8 }) {
      TextInput({ text: this.inputText })
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
          if (this.inputText.trim() && !this.isSending) {
            this.sendMessage();
          }
        })

      Button(this.isSending ? '发送中...' : '发送', { type: ButtonType.Normal })
        .fontSize(14)
        .backgroundColor(this.isSending ? '#A0CFFF' : '#337EFF')
        .fontColor('#FFFFFF')
        .borderRadius(20)
        .width(80)
        .height(40)
        .enabled(!this.isSending && !!this.inputText.trim())
        .onClick(() => {
          this.sendMessage();
        })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderColor('#E5E6EB')
    .borderWidth({ top: 1 })
  }

  // 核心：发送消息+SSE流式处理（原页面的sendMessage逻辑迁移）
  private async sendMessage() {
    if (!this.inputText.trim() || this.isSending || !this.isLoggedIn) {
      if (!this.isLoggedIn) {
        promptAction.showToast({ message: '请先登录后再发送消息' });
      }
      return;
    }

    // 用户消息
    const userMessage = this.inputText.trim();

    if (this.isNewSession && !this.hasGeneratedTitle && this.messageList.length === 0) {
      console.log(`📢新建会话${this.sessionId}第一条消息，开始生成标题:`, userMessage);
      await this.callGenerateTitleApi(userMessage);
      this.hasGeneratedTitle = true; // 标记已生成，避免重复
    }

    // 1. 获取Token
    let token = '';
    try {
      const storageToken = await storageUtil.get('token');
      token = storageToken ? storageToken.toString() : '';
    } catch (error) {
      console.error('获取Token失败:', error);
      return;
    }

    this.inputText = '';
    this.isSending = true;

    const userMsgItem: MessageItem = {
      id: Date.now(),
      sessionId: this.sessionId,
      userId: this.userId,
      role: 'user',
      content: userMessage,
      modelName: 'qwen-turbo',
      status: 1,
      statusDesc: '成功',
      createTime: new Date().toISOString()
    };

    const assistantMsgItem: MessageItem = {
      id: Date.now() + 1,
      sessionId: this.sessionId,
      userId: 0,
      role: 'assistant',
      content: '',
      modelName: 'qwen-turbo',
      status: 0,
      statusDesc: '思考中...',
      createTime: new Date().toISOString()
    };

    // 更新消息列表
    this.messageList = [...this.messageList, userMsgItem];
    this.currentAssistantMessage = assistantMsgItem;

    try {
      // 关闭旧连接
      this.streamController?.close();
      this.streamController = null;
      let accumulatedContent = '';

      // 3. 构建SSE请求
      const streamOptions: StreamChatOptions = {
        token: token,
        params: {
          sessionId: this.sessionId,
          modelName: 'qwen-turbo',
          content: userMessage
        },
        onMessage: (data: string) => {
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
          console.error('SSE连接错误:', error.message);
          const msg = error.message.includes('Token') ? '登录已过期，请重新登录' : `请求失败: ${error.message}`;
          promptAction.showToast({ message: msg });
          this.handleStreamEnd(msg, false);
        },
        onComplete: () => {
          this.handleStreamEnd(accumulatedContent || '无回复内容', true);
        }
      };

      // 4. 发起SSE请求
      this.streamController = await MessageApi.streamChat(streamOptions);
      if (!this.streamController) {
        throw new Error('无法创建SSE连接');
      }

      // 超时检测
      setTimeout(() => {
        if (this.isSending && accumulatedContent === '') {
          this.handleStreamEnd('请求超时，请重试', false);
        }
      }, 30000);

    } catch (error) {
      console.error('发送消息失败:', error);
      this.handleStreamEnd(`发送失败: ${(error as Error).message}`, false);
    }
  }

  // 更新AI回复内容（抽离的辅助方法）
  private updateAssistantMessage(content: string, statusDesc: string) {
    if (this.currentAssistantMessage) {
      this.currentAssistantMessage = {
        id: this.currentAssistantMessage.id,
        sessionId: this.currentAssistantMessage.sessionId,
        userId: this.currentAssistantMessage.userId,
        role: this.currentAssistantMessage.role,
        content: content, // 仅更新内容
        modelName: this.currentAssistantMessage.modelName,
        status: this.currentAssistantMessage.status,
        statusDesc: statusDesc, // 仅更新状态
        createTime: this.currentAssistantMessage.createTime
      };
    }
  }

  // 流式结束处理（原页面的handleStreamEnd逻辑迁移）
  private handleStreamEnd(content: string, success: boolean) {
    if (this.currentAssistantMessage) {
      const completedMsg: MessageItem = {
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

    // 清理资源
    this.streamController?.close();
    this.streamController = null;
    this.isSending = false;
  }

  // 工具方法：格式化时间
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

  // 组件销毁时关闭连接
  aboutToDisappear() {
    this.streamController?.close();
  }

  private async callGenerateTitleApi(userMessage: string) {
    try {
      const params: GenerateSessionTitleParams = {
        userFirstMessage: userMessage.trim()
      };
      const result = await SessionApi.generateSessionTitle(this.sessionId, params);

      if (result) {
        console.log(`🤖会话${this.sessionId}自动生成标题成功:`, result.title);
        // 通知ChatPage更新标题
        postCardAction(this, {
          action: 'updateSessionTitle',
          params: {
            sessionId: this.sessionId,
            title: result.title
          }
        });
      } else {
        console.error(`❌会话${this.sessionId}生成标题接口返回null`);
      }
    } catch (error) {
      console.error(`❌会话${this.sessionId}调用生成标题接口异常:`, error);
    }
  }
}