// SessionDetailPage.ts - 完整代码
import { MessagePageDTO, MessageRecordVO } from '../types/MessageType';
import { MessageApi, StreamChatOptions, SSEStreamController } from '../api/MessageApi';
import { MessageBubble } from '../components/MessageBubble';
import { RouterModule } from 'basic';
import { storageUtil } from 'storage';
import promptAction from '@ohos.promptAction';

// 消息项接口
interface MessageItem {
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

interface UserInfo {
  id?: number;
  username?: string;
  nickname?: string;
  avatar?: string;
  email?: string;
  mobile?: string;
}

@Builder
export function SessionDetailPageBuilder() {
  SessionDetailPage()
}

@Component
export struct SessionDetailPage {
  @State messageList: MessageItem[] = [];
  @State loading: boolean = false;
  @State sessionId: number = 0;
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State currentAssistantMessage: MessageItem | null = null;
  private streamController: SSEStreamController | null = null;
  @Watch('onLoginStateChange')
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null;

  // 监听登录状态变化
  private onLoginStateChange() {
    console.log('登录状态变化:', this.isLoggedIn);
    if (!this.isLoggedIn) {
      console.log('用户已退出登录');
      this.currentAssistantMessage = null;
      this.isSending = false;
    }
  }

  aboutToAppear() {
    const stack = RouterModule.getStack();
    const param = stack.getParamByIndex(stack.size() - 1) as Record<string, number>;
    if (param && param['sessionId']) {
      this.sessionId = param['sessionId'];
      console.info('NavPathStack 拿到 sessionId = ' + this.sessionId);
      this.loadMessages();
    } else {
      console.error('NavPathStack 未拿到 sessionId');
    }
  }

  async loadMessages() {
    this.loading = true;
    try {
      const params: MessagePageDTO = {
        sessionId: this.sessionId,
        current: 1,
        size: 20
      };

      const result = await MessageApi.getMessageList(params);
      if (result && result.records) {
        this.messageList = result.records.map(record => this.convertMessageRecord(record));
      }
    } catch (error) {
      console.error('加载消息失败:', error);
    } finally {
      this.loading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        this.buildHeader()

        Scroll() {
          Column({ space: 16 }) {
            if (this.loading && this.messageList.length === 0) {
              Text('加载历史消息中...')
                .fontSize(14)
                .fontColor('#8F959E')
                .margin({ top: 20 });
            }

            ForEach(this.messageList, (item: MessageItem) => {
              MessageBubble({
                content: item.content,
                isUser: item.role === 'user',
                time: this.formatTime(item.createTime),
                statusDesc: item.statusDesc,
                isAssistant: item.role === 'assistant',
                userAvatar: $r('app.media.avatar_img'),
                aiAvatar: $r('app.media.avatar_img')
              })
            })

            if (this.currentAssistantMessage) {
              MessageBubble({
                content: this.currentAssistantMessage.content,
                isUser: false,
                time: '',
                statusDesc: '思考中...',
                isAssistant: true,
                userAvatar: $r('app.media.avatar_img'),
                aiAvatar: $r('app.media.avatar_img')
              })
            }
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)

        this.buildInputArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F9FA')
    }
  }

  @Builder
  buildHeader() {
    Row() {
      Text('会话详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2329')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button('测试')
        .fontSize(12)
        .backgroundColor('#52C41A')
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .width(60)
        .height(30)
        .margin({ left: 8 })
        .onClick(() => {
          this.testStreamConnection();
        })
    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor('#FFFFFF')
    .borderColor('#E5E6EB')
    .borderWidth({ bottom: 1 })
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

  private async sendMessage() {
    // 1. 基础校验
    if (!this.inputText.trim() || this.isSending) {
      return;
    }

    // 2. 登录状态 + Token 校验
    let token = '';
    try {
      const storageToken = await storageUtil.get('token');
      token = storageToken ? storageToken.toString() : '';
    } catch (error) {
      console.error('获取Token失败:', error);
    }

    // 未登录/无Token时提示并返回
    if (!this.isLoggedIn || !token) {
      promptAction.showToast({
        message: '请先登录后再发送消息',
        duration: 2000
      });
      return;
    }

    // 3. 构建用户消息
    const userMessage = this.inputText.trim();
    this.inputText = '';
    this.isSending = true;

    console.log('开始发送消息:', userMessage);
    console.log('sessionId:', this.sessionId);
    console.log('携带Token长度:', token.length);

    const userMsgItem: MessageItem = {
      id: Date.now(),
      sessionId: this.sessionId,
      userId: this.currentUserInfo?.id || 1,
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
    const newMessageList = [...this.messageList];
    newMessageList.push(userMsgItem);
    this.messageList = newMessageList;
    this.currentAssistantMessage = assistantMsgItem;

    try {
      // 关闭旧连接
      if (this.streamController) {
        console.log('关闭之前的SSE连接');
        this.streamController.close();
        this.streamController = null;
      }

      let accumulatedContent = '';

      // 4. 构建流式请求参数
      const streamOptions: StreamChatOptions = {
        token: token,
        params: {
          sessionId: this.sessionId,
          modelName: 'qwen-turbo',
          content: userMessage
        },
        // 修改 onMessage 回调，添加原始数据处理
        onMessage: (data: string) => {
          console.log('收到原始SSE数据:', data);

          // 先尝试按行分割处理
          const lines = data.split('\n');
          for (const line of lines) {
            const trimmedLine = line.trim();
            if (trimmedLine === '') {
              continue;
            }

            console.log('处理行:', trimmedLine.substring(0, 50) + '...');

            // 检查是否是SSE格式
            if (trimmedLine.startsWith('data:')) {
              const content = trimmedLine.substring(5).trim();
              if (content === '[DONE]') {
                console.log('收到结束标记');
                this.handleStreamEnd(accumulatedContent, true);
                return;
              }

              if (content) {
                accumulatedContent += content;
                console.log('追加内容，当前长度:', accumulatedContent.length);

                // 更新UI
                if (this.currentAssistantMessage) {
                  const updatedMessage: MessageItem = {
                    id: this.currentAssistantMessage.id,
                    sessionId: this.currentAssistantMessage.sessionId,
                    userId: this.currentAssistantMessage.userId,
                    role: this.currentAssistantMessage.role,
                    content: accumulatedContent,
                    modelName: this.currentAssistantMessage.modelName,
                    status: 1,
                    statusDesc: '回复中...',
                    createTime: this.currentAssistantMessage.createTime
                  };
                  this.currentAssistantMessage = updatedMessage;
                }
              }
            } else {
              // 如果不是data:格式，直接处理
              console.log('非标准格式，直接处理:', trimmedLine.substring(0, 50) + '...');
              accumulatedContent += trimmedLine;

              if (this.currentAssistantMessage) {
                const updatedMessage: MessageItem = {
                  id: this.currentAssistantMessage.id,
                  sessionId: this.currentAssistantMessage.sessionId,
                  userId: this.currentAssistantMessage.userId,
                  role: this.currentAssistantMessage.role,
                  content: accumulatedContent,
                  modelName: this.currentAssistantMessage.modelName,
                  status: 1,
                  statusDesc: '回复中...',
                  createTime: this.currentAssistantMessage.createTime
                };
                this.currentAssistantMessage = updatedMessage;
              }
            }
          }
        },
        onError: (error: Error) => {
          console.error('SSE连接错误:', error.message);

          if (error.message.includes('未登录') || error.message.includes('Token') || error.message.includes('认证')) {
            promptAction.showToast({
              message: '登录已过期，请重新登录',
              duration: 2000
            });
            this.isLoggedIn = false;
          } else if (error.message.includes('HTTP')) {
            promptAction.showToast({
              message: '服务器错误: ' + error.message,
              duration: 2000
            });
          }

          this.handleStreamEnd('请求失败: ' + error.message, false);
        },
        onComplete: () => {
          console.log('SSE连接完成');

          if (accumulatedContent === '') {
            console.log('SSE完成但无内容，可能是认证问题');
            this.handleStreamEnd('连接异常结束，请检查登录状态', false);
          } else {
            this.handleStreamEnd(accumulatedContent, true);
          }
        }
      };

      // 调用流式接口
      this.streamController = await MessageApi.streamChat(streamOptions);

      if (!this.streamController) {
        throw new Error('无法创建SSE连接');
      }

      console.log('SSE连接创建成功');

      // 设置超时检测
      setTimeout(() => {
        if (this.isSending && accumulatedContent === '') {
          console.log('SSE连接超时，没有收到任何数据');
          this.handleStreamEnd('请求超时，请重试', false);
        }
      }, 30000);

    } catch (error) {
      console.error('发送消息失败:', error);
      this.handleStreamEnd('发送失败: ' + (error as Error).message, false);
    }
  }

  private async testStreamConnection() {
    // 先校验Token
    let token = '';
    try {
      const storageToken = await storageUtil.get('token');
      token = storageToken ? storageToken.toString() : '';
    } catch (error) {
      console.error('获取Token失败:', error);
    }

    if (!this.isLoggedIn || !token) {
      promptAction.showToast({ message: '请先登录' });
      return;
    }

    try {
      console.log('开始测试SSE连接...');
      let testContent = '';

      const testOptions: StreamChatOptions = {
        token: token,
        params: {
          sessionId: this.sessionId || 1,
          modelName: 'qwen-turbo',
          content: '测试消息'
        },
        onMessage: (data: string) => {
          console.log('测试收到数据:', data);
          testContent += data;
        },
        onError: (error: Error) => {
          console.error('测试连接错误:', error);
          if (error.message.includes('未登录')) {
            promptAction.showToast({ message: '登录已过期' });
          }
        },
        onComplete: () => {
          console.log('测试连接完成，收到内容长度:', testContent.length);
        }
      };

      const testStreamController = await MessageApi.streamChat(testOptions);

      if (testStreamController) {
        console.log('测试连接成功建立');
        setTimeout(() => {
          testStreamController.close();
          console.log('测试连接已关闭');
        }, 5000);
      } else {
        console.error('测试连接创建失败');
      }

    } catch (error) {
      console.error('测试连接异常:', error);
    }
  }

  private handleStreamEnd(content: string, success: boolean) {
    console.log('流式传输结束，成功:', success, '内容长度:', content ? content.length : 0);

    if (this.currentAssistantMessage) {
      const completedMsg: MessageItem = {
        id: this.currentAssistantMessage.id,
        sessionId: this.currentAssistantMessage.sessionId,
        userId: this.currentAssistantMessage.userId,
        role: this.currentAssistantMessage.role,
        content: content || (success ? '收到空回复' : '没有收到回复'),
        modelName: this.currentAssistantMessage.modelName,
        status: success ? 1 : 2,
        statusDesc: success ? '成功' : '失败',
        createTime: new Date().toISOString()
      };

      const newMessageList = [...this.messageList];
      newMessageList.push(completedMsg);
      this.messageList = newMessageList;

      console.log('消息已添加到列表，总消息数:', this.messageList.length);
      this.saveMessage(completedMsg);
    }

    // 清理streamController
    if (this.streamController) {
      this.streamController.close();
      this.streamController = null;
    }

    // 重置状态
    this.currentAssistantMessage = null;
    this.isSending = false;
    console.log('发送状态已重置');
  }

  private async saveMessage(message: MessageItem) {
    try {
      console.log('消息需要保存，内容:', message.content ? message.content.substring(0, 100) + '...' : '空内容');
    } catch (error) {
      console.error('保存消息失败:', error);
    }
  }

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

  aboutToDisappear() {
    if (this.streamController) {
      console.log('页面销毁，关闭SSE连接');
      this.streamController.close();
      this.streamController = null;
    }
  }

  private convertMessageRecord(record: MessageRecordVO): MessageItem {
    return {
      id: record.id,
      sessionId: record.sessionId,
      userId: record.userId,
      role: record.role as 'user' | 'assistant',
      content: record.content,
      modelName: record.modelName,
      status: record.status,
      statusDesc: record.statusDesc,
      createTime: record.createTime
    };
  }
}