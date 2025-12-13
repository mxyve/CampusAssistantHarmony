import {
  MessagePageDTO
} from '../types/MessageType';

import { MessageApi } from '../api/MessageApi';

import { MessageBubble } from '../components/MessageBubble';

import { RouterModule } from 'basic';

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

@Builder
export function SessionDetailPageBuilder() {
  SessionDetailPage()
}

@Component
export struct SessionDetailPage {
  @State messageList: MessageItem[] = [];
  @State loading: boolean = false;
  @State sessionId: number = 0;

  aboutToAppear() {
    // ① 从 RouterModule 里拿到同一个栈
    const stack = RouterModule.getStack();

    // ② 取当前页面参数（栈顶）
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
        sessionId: this.sessionId, // 从路由参数获取
        current: 1,
        size: 20
      };

      const result = await MessageApi.getMessageList(params);
      if (result && result.records) {
        this.messageList = result.records;
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
        // 顶部栏
        this.buildHeader()

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
                userAvatar: $r('app.media.avatar_img'), // 用户头像
                aiAvatar: $r('app.media.avatar_img')      // AI头像
              })
            })
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)

        // 底部输入栏
        this.buildInputArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F9FA')
    }
  }

  // 顶部栏
  @Builder
  buildHeader() {
    Row() {

      Text('会话详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2329')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
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

  // 底部输入栏
  @Builder
  buildInputArea() {
    Row({ space: 8 }) {
      // 输入框
      TextInput()
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderColor('#E5E6EB')
        .borderWidth(1)
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .height(40)

      // 发送按钮
      Button('发送', { type: ButtonType.Normal })
        .fontSize(14)
        .backgroundColor('#337EFF')
        .fontColor('#FFFFFF')
        .borderRadius(20)
        .width(60)
        .height(40)
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderColor('#E5E6EB')
    .borderWidth({ top: 1 })
  }

  // 时间格式化
  private formatTime(timeStr: string): string {
    if (!timeStr) {
      return '';
    }
    const date = new Date(timeStr);
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }
}