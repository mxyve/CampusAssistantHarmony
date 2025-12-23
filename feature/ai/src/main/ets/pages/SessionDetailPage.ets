import { MessagePageDTO, MessageRecordVO } from '../types/MessageType';
import { MessageApi } from '../api/MessageApi';
import { RouterModule } from 'basic';
import { StreamChatComponent, MessageItem } from '../components/StreamChatComponent'; // 导入封装的组件

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
  @State sessionId: number = 0;
  @State loading: boolean = false;
  @State initialMessages: MessageItem[] = []; // 历史消息（传给组件）
  @Watch('onLoginStateChange')
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null;

  aboutToAppear() {
    // 1. 获取sessionId
    const stack = RouterModule.getStack();
    const param = stack.getParamByIndex(stack.size() - 1) as Record<string, number>;
    if (param?.sessionId) {
      this.sessionId = param.sessionId;
      this.loadHistoryMessages(); // 加载历史消息
    }
  }

  // 加载历史消息（仅负责“获取数据”，渲染交给组件）
  private async loadHistoryMessages() {
    this.loading = true;
    try {
      const params: MessagePageDTO = {
        sessionId: this.sessionId,
        current: 1,
        size: 20
      };
      const result = await MessageApi.getMessageList(params);
      if (result?.records) {
        this.initialMessages = result.records.map(record => this.convertMessageRecord(record));
      }
    } catch (error) {
      console.error('加载历史消息失败:', error);
    } finally {
      this.loading = false;
    }
  }

  // 监听登录状态变化
  private onLoginStateChange() {
    console.log('登录状态变化:', this.isLoggedIn);
  }

  build() {
    NavDestination() {
      Column() {
        // 页面Header（保留在容器页）
        this.buildHeader()

        // 加载中提示
        if (this.loading) {
          Text('加载历史消息中...')
            .fontSize(14)
            .fontColor('#8F959E')
            .margin({ top: 20 });
        } else {
          // 复用流式问答组件
          StreamChatComponent({
            sessionId: this.sessionId,
            initialMessages: this.initialMessages,
            userId: this.currentUserInfo?.id || 0,
            isLoggedIn: this.isLoggedIn
          })
            .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
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

  // 转换历史消息格式
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