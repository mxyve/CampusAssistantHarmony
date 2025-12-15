// ScholarshipPage.ets
import { RouterModule, RouterMap } from 'basic';
import { ScholarshipChatComponent } from '../../../components/ScholarshipChatComponent';
import { ScholarshipMessageItem } from '../../../types/ScholarshipType';
import { storageUtil } from 'storage';

interface UserInfo {
  id?: number;
}

@Builder
export function ScholarshipPageBuilder() {
  ScholarshipPage()
}

@Component
@Entry
struct ScholarshipPage {
  @State sessionId: number = 999;
  @State initialMessages: ScholarshipMessageItem[] = [
    {
      id: 1,
      sessionId: 999,
      userId: 0,
      role: 'assistant',
      content: '你好！我是奖助AI助手，可解答以下问题：\n1. 国家奖学金/助学金申请条件\n2. 奖助学金发放时间\n3. 申请流程及所需材料\n4. 其他奖助相关问题',
      modelName: 'bailian-agent',
      status: 1,
      statusDesc: '成功',
      createTime: new Date().toISOString()
    }
  ];
  @State userId: number = 0;
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null;
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false; // 新增登录状态监听

  aboutToAppear() {
    this.getUserId();
  }

  build() {
    NavDestination() {
      Column() {
        this.buildHeader()

        // 传递isLoggedIn给组件
        ScholarshipChatComponent({
          sessionId: this.sessionId,
          initialMessages: this.initialMessages,
          userId: this.userId,
          isLoggedIn: this.isLoggedIn // 新增参数
        })
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  @Builder
  buildHeader() {
    Row() {
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
      }
      .backgroundColor('transparent')
      .onClick(() => {
        RouterModule.pop();
      })

      Text('奖助AI助手')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('')
        .width(24)
    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor('#FFFFFF')
  }

  // 修复类型报错的getUserId方法
  private async getUserId() {
    try {
      const rawGlobalUserInfo = AppStorage.get<UserInfo>('currentUserInfo');
      const globalUserInfo: UserInfo | null = rawGlobalUserInfo ?? null; // 关键：undefined 转 null
      if (globalUserInfo?.id) {
        this.userId = globalUserInfo.id;
        return;
      }

      const localUserInfo: UserInfo | null = await storageUtil.getObject<UserInfo>('userInfo');
      this.userId = localUserInfo?.id || 0;
    } catch (e) {
      console.error('获取用户ID失败:', e);
      this.userId = 0;
    }
  }
}