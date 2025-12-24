import { RouterModule, RouterMap } from 'basic';
import { StreamChatComponent, MessageItem } from '../components/StreamChatComponent';
import promptAction from '@ohos.promptAction';

interface UserInfo {
  id?: number;
  username?: string;
  nickname?: string;
  avatar?: string;
}

@Builder
export function ChatPageBuilder() {
  ChatPage()
}

@Component
export struct ChatPage {
  @State sessionId: number = 0;
  @State initialMessages: MessageItem[] = []; // 新建会话无历史消息，为空数组
  @Watch('onLoginStateChange')
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null;
  // 存储会话标题（用于页面显示）
  @State sessionTitle: string = '新建对话';

  aboutToAppear() {
    // 1. 获取跳转携带的sessionId
    const stack = RouterModule.getStack();
    const param = stack.getParamByIndex(stack.size() - 1) as Record<string, number>;

    if (param && param['sessionId']) {
      this.sessionId = param['sessionId'];
      console.log('🔢ChatPage获取到sessionId:', this.sessionId);
    } else {
      console.error('ChatPage未获取到sessionId');
      promptAction.showToast({ message: '会话ID异常' });
      RouterModule.push(RouterMap.AI_PAGE); // 异常时返回AI列表页
    }
  }

  // 监听登录状态变化
  private onLoginStateChange() {
    console.log('ChatPage登录状态变化:', this.isLoggedIn);
    if (!this.isLoggedIn) {
      RouterModule.push(RouterMap.AI_PAGE); // 退出登录返回列表页
    }
  }

  // 通知AiPage刷新列表
  private notifyAiPageRefresh() {
    try {
      postCardAction(this, {
        action: 'refreshSessionList',
        params: {}
      });
    } catch (error) {
      console.error('通知刷新失败:', error);
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 页面Header（简化版，可参考SessionDetailPage）
        this.buildHeader()

        // 复用流式问答组件（新建会话无历史消息，initialMessages为空）
        StreamChatComponent({
          sessionId: this.sessionId,
          initialMessages: this.initialMessages,
          userId: this.currentUserInfo?.id || 0,
          isLoggedIn: this.isLoggedIn
        })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F9FAFB')
    }
  }

  @Builder
  buildHeader() {
    Row() {
      // 返回按钮
      Button({ type: ButtonType.Circle, stateEffect: true })
        .width(32)
        .height(32)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          RouterModule.push(RouterMap.AI_PAGE); // 返回AI列表页
          this.notifyAiPageRefresh(); // 返回时强制刷新AiPage列表
        })

      Text(this.sessionTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2329')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位符（保持布局对称）
      Column().width(32).height(32)
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
}