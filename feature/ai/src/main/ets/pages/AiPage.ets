import { RouterModule, RouterMap } from 'basic';
import { SessionApi } from '../api/SessionApi';
import { SessionRecordVO, SessionPageDTO } from '../types/SessionType';

interface UserInfo {
  id?: number;
  username?: string;
  nickname?: string;
  avatar?: string;
  email?: string;
  mobile?: string;
}

interface SessionDetailParams {
  sessionId: number;
}

@Builder
export function AiPageBuilder() {
  AiPage()
}

@Component
export struct AiPage {
  @State sessionList: SessionRecordVO[] = [];
  @State loading: boolean = false;
  @Watch('onLoginStateChange')
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @Watch('onUserInfoChange')
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null;

  // 添加生命周期函数
  aboutToAppear() {
    setTimeout(() => {
      this.loadSessionList();
    }, 300);
  }

  // 监听用户信息变化，自动重新加载列表
  private onUserInfoChange() {
    console.log('用户信息发生变化，重新加载会话列表');
    this.loadSessionList();
  }

  // 监听登录状态变化，自动重新加载列表
  private onLoginStateChange() {
    console.log('登录状态变化:', this.isLoggedIn);
    if (this.isLoggedIn) {
      this.loadSessionList(); // 登录成功后重新加载
    } else {
      this.sessionList = []; // 退出登录清空列表
    }
  }

  // 加载会话列表的方法
  async loadSessionList() {
    console.log('开始加载会话列表...');
    const userId = this.currentUserInfo?.id;
    console.log('当前登录用户ID:', userId);

    if (!userId) {
      console.warn('用户未登录/用户ID为空，无法获取会话列表');
      this.sessionList = []; // 清空列表
      this.loading = false; // 重置加载态
      return;
    }

    this.loading = true;
    try {
      const params: SessionPageDTO = {
        userId: userId,
        current: 1,
        size: 10
      };

      console.log('调用API参数:', JSON.stringify(params));

      const result = await SessionApi.getSessionList(params);
      console.log('API返回结果:', result);

      if (result && result.records) {
        console.log(`获取到 ${result.records.length} 条记录`);
        this.sessionList = result.records;
      } else {
        this.sessionList = [];
      }
    } catch (error) {
      console.error('加载会话列表失败:', error);
      this.sessionList = [];
    } finally {
      this.loading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        this.buildHeader()

        // 会话列表
        if (this.sessionList.length === 0) {
          this.buildEmptyView()
        } else {
          List({ space: 0 }) {
            ForEach(this.sessionList, (item: SessionRecordVO) => {
              ListItem() {
                this.buildSessionItem(item)
              }
            }, (item: SessionRecordVO) => item.id.toString())
          }
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F9FAFB')
    }
  }

  // 顶部栏 - 简洁风格
  @Builder
  buildHeader() {
    Row() {
      // 标题
      Text('消息')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2329')
        .layoutWeight(1)

      // 新增按钮
      Button('新建', { type: ButtonType.Normal })
        .fontSize(14)
        .backgroundColor('#337EFF')
        .fontColor('#FFFFFF')
        .borderRadius(4)
        .padding({
          left: 12,
          right: 12,
          top: 6,
          bottom: 6
        })
        .onClick(() => {
          RouterModule.push(RouterMap.CHAT_PAGE);
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

  // 会话项 - 简洁卡片风格
  @Builder
  buildSessionItem(item: SessionRecordVO) {
    Row({ space: 12 }) {
      // 左侧图标
      Column() {
        Image($r('app.media.avatar_img'))
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#F2F3F5')
      }
      .justifyContent(FlexAlign.Center)

      // 右侧内容
      Column({ space: 4 }) {
        // 标题行
        Row() {
          Text(item.title || '未命名会话')
            .fontSize(16)
            .fontColor('#1F2329')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.formatRelativeTime(item.lastMessageTime || item.createTime))
            .fontSize(12)
            .fontColor('#8F959E')
        }
        .width('100%')

        // 内容预览
        Text(item.lastMessage || `模型：${item.modelName}`)
          .fontSize(14)
          .fontColor('#8F959E')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      console.log('点击会话，ID:', item.id);
      const params: SessionDetailParams = { sessionId: item.id };
      RouterModule.push(RouterMap.SESSION_DETAIL_PAGE, params);
    })
  }

  // 空状态
  @Builder
  buildEmptyView() {
    Column({ space: 12 }) {
      Image($r('app.media.avatar_img')) // 空状态图标
        .width(120)
        .height(120)
        .objectFit(ImageFit.Contain)

      Text('暂无对话')
        .fontSize(16)
        .fontColor('#1F2329')
        .fontWeight(FontWeight.Medium)

      Button('新建对话', { type: ButtonType.Normal })
        .margin({ top: 16 })
        .fontSize(14)
        .backgroundColor('#337EFF')
        .fontColor('#FFFFFF')
        .borderRadius(6)
        .width(120)
        .height(36)
        .onClick(() => {
          RouterModule.push(RouterMap.CHAT_PAGE);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // 相对时间格式化（更简洁的时间显示）
  private formatRelativeTime(timeStr: string): string {
    if (!timeStr) {
      return '';
    }

    const now = new Date();
    const date = new Date(timeStr);
    const diffHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));

    if (diffHours < 1) {
      return '刚刚';
    } else if (diffHours < 24) {
      return `${diffHours}小时前`;
    } else if (diffHours < 48) {
      return '昨天';
    } else if (diffHours < 168) { // 7天内
      const days = Math.floor(diffHours / 24);
      return `${days}天前`;
    } else {
      return `${date.getMonth() + 1}-${date.getDate()}`;
    }
  }
}