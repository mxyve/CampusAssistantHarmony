import { RouterModule, RouterMap } from 'basic';
import { SessionApi, CreateSessionParams } from '../api/SessionApi';
import { SessionRecordVO, SessionPageDTO } from '../types/SessionType';
import promptAction from '@ohos.promptAction';

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

interface ChatPageParams {
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
  @State isRefreshing: boolean = false; // 下拉刷新状态
  private listScroller: ListScroller = new ListScroller();

  // 添加生命周期函数
  aboutToAppear() {
    this.loadSessionList();
  }

  // 页面每次显示时（包括返回）刷新列表
  onPageShow() {
    console.log('AiPage 页面显示，刷新会话列表');
    if (this.isLoggedIn) {
      this.loadSessionList();
    }
  }

  // 监听用户信息变化，自动重新加载列表
  private onUserInfoChange() {
    console.log('用户信息发生变化，重新加载会话列表');
    if (this.isLoggedIn) {
      this.loadSessionList();
    } else {
      this.sessionList = [];
    }
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
      this.isRefreshing = false; // 重置下拉刷新状态
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
      this.isRefreshing = false;
    }

  }

  build() {
    NavDestination() {
      Refresh({
        refreshing: this.isRefreshing,
      }) {
        Column() {
          // 顶部栏
          this.buildHeader()

          // 会话列表
          if (this.sessionList.length === 0) {
            this.buildEmptyView()
          } else {
            List({ space: 0, scroller: this.listScroller }) {
              ForEach(this.sessionList, (item: SessionRecordVO) => {
                ListItem() {
                  this.buildSessionItem(item)
                }
                .transition({ type: TransitionType.Delete, opacity: 0 })
                .swipeAction({
                  end: {
                    builder: () => {
                      // 左滑显示按钮区域
                      return this.buildSwipeButtons(item);
                    },
                    onAction: (action?: string) => {
                      if (action === 'delete') {
                        console.log('删除会话，ID:', item.id);
                        // 添加删除逻辑
                        animateTo({ duration: 300 }, () => {
                          // 删除动画
                          const index = this.sessionList.findIndex(i => i.id === item.id);
                          if (index != -1) {
                            this.sessionList.splice(index, 1);
                          }
                        });
                      } else if (action === 'pin') {
                        console.log('执行置顶，会话ID:', item.id);
                        // 这里添加置顶逻辑
                        // 暂时先关闭左滑菜单
                        this.listScroller.closeAllSwipeActions();
                      }
                    },
                    actionAreaDistance: 120,
                  }
                })
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
      .onRefreshing(async () => {
        console.log('触发下拉刷新');
        this.isRefreshing = true;
        await this.loadSessionList();
        promptAction.showToast({ message: '刷新完成' })
      })
      .width('100%')
      .height('100%')
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
          this.createNewSessionAndJump(); // 替换原有直接跳转的逻辑
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

  // 空状态
  @Builder
  buildEmptyView() {
    Column({ space: 12 }) {
      Image($r('app.media.robot')) // 空状态图标
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

  // 左滑按钮区域
  @Builder
  buildSwipeButtons(item: SessionRecordVO) {
    Row() {
      // 置顶按钮
      Button({ type: ButtonType.Normal }) {
        Text('置顶')
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
      .width(60)
      .height('100%')
      .backgroundColor('#FFA940') // 橙色
      .borderRadius(0)
      .onClick(() => {
        console.log('点击置顶按钮，会话ID:', item.id);
        // 触发 swipeAction 的 onAction，传递 'pin' 参数
        // 需要手动触发左滑菜单的onAction
        // 这里先简单处理，实际开发中可能需要更复杂的机制
        this.listScroller.closeAllSwipeActions();
        // 可以在这里直接调用置顶方法
        this.handlePinSession(item);
      })

      // 删除按钮
      Button({ type: ButtonType.Normal }) {
        Text('删除')
          .fontSize(14)
          .fontColor('#FFFFFF')
      }
      .width(60)
      .height('100%')
      .backgroundColor('#FF4D4F') // 红色
      .borderRadius(0)
      .onClick(() => {
        console.log('点击删除按钮，会话ID:', item.id);
        // 显示确认对话框
        this.showDeleteConfirmDialog(item);
      })
    }
    .height('100%')
    .justifyContent(FlexAlign.Start)
  }

  // 置顶处理方法
  private handlePinSession(item: SessionRecordVO) {
    console.log('处理置顶逻辑，会话ID:', item.id);
    // 这里实现置顶逻辑
    // 1. 如果是置顶，取消置顶
    // 2. 如果是未置顶，置顶

    // 示例：切换置顶状态
    const updatedList = this.sessionList.map(session => {
      if (session.id === item.id) {
        // 手动创建新对象，复制所有属性
        return {
          id: session.id,
          title: session.title,
          modelName: session.modelName,
          status: session.status,
          lastMessage: session.lastMessage,
          lastMessageTime: session.lastMessageTime,
          createTime: session.createTime,
          updateTime: session.updateTime,
          isPinned: !(session.isPinned || false)  // 切换置顶状态
        };
      }
      return session;
    });

    // 排序：置顶的在前
    this.sessionList = updatedList.sort((a, b) => {
      if (a.isPinned && !b.isPinned) {
        return -1;
      }
      if (!a.isPinned && b.isPinned) {
        return 1;
      }
      return 0;
    });

    promptAction.showToast({
      message: item.isPinned ? '已取消置顶' : '已置顶'
    });
  }

  // 显示删除确认对话框
  private showDeleteConfirmDialog(item: SessionRecordVO) {
    // 使用鸿蒙的确认对话框
    try {
      promptAction.showDialog({
        title: '删除确认',
        message: `确定要删除会话"${item.title || '未命名会话'}"吗？`,
        buttons: [
          {
            text: '取消',
            color: '#000000'
          },
          {
            text: '删除',
            color: '#FF4D4F'
          }
        ]
      })
        .then((result) => {
          if (result.index === 1) { // 点击了删除按钮
            console.log('用户确认删除，会话ID:', item.id);
            // 执行删除
            this.handleDeleteSession(item);
          } else {
            console.log('用户取消删除');
            // 关闭左滑菜单
            this.listScroller.closeAllSwipeActions();
          }
        })
        .catch((error: Error) => {
          console.error('显示对话框失败:', error);
        });
    } catch (error) {
      console.error('调用对话框API失败:', error);
      this.showSimpleConfirmDialog(item);
    }
  }

  // 简单确认对话框（备用）
  private showSimpleConfirmDialog(item: SessionRecordVO) {
    // 可以自定义一个简单的对话框
    promptAction.showToast({
      message: '请稍后重试删除操作',
      duration: 2000
    });
    // 或者使用全局的confirm（如果可用）
    this.listScroller.closeAllSwipeActions();
  }

  // AiPage.ts 中的 handleDeleteSession 方法
  private async handleDeleteSession(item: SessionRecordVO) {
    console.log('执行删除逻辑，会话ID:', item.id);

    try {
      // 1. 调用后端删除接口
      const deleteSuccess = await SessionApi.deleteSession(item.id);
      if (!deleteSuccess) {
        promptAction.showToast({ message: '删除失败，请重试' });
        return;
      }

      // 2. 前端动画删除列表项
      animateTo({ duration: 300 }, () => {
        const index = this.sessionList.findIndex(i => i.id === item.id);
        if (index !== -1) {
          this.sessionList.splice(index, 1);
        }
      });

      promptAction.showToast({ message: '已删除' });
    } catch (error) {
      console.error('删除会话失败:', error);
      promptAction.showToast({ message: '删除失败，请重试' });
    }
  }

  // 修改会话项，添加置顶标识
  @Builder
  buildSessionItem(item: SessionRecordVO) {
    Row({ space: 12 }) {
      // 左侧图标
      Column() {
        Stack() {
          // 光圈背景（根据ID规则生成不同颜色）
          Circle()
            .width(46)
            .height(46)
            .fill(this.getAvatarCircleColor(item.id || 0))
            .opacity(0.2)

          Image($r('app.media.robot'))
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor('#F2F3F5')
        }
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

          // 如果置顶，显示置顶标签
          if (item.isPinned) {
            Text('[置顶]')
              .fontSize(10)
              .fontColor('#FFA940')
              .margin({ left: 4 })
          }

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

  // 新增：创建会话并跳转的方法
  private async createNewSessionAndJump() {
    // 1. 登录态校验
    if (!this.isLoggedIn) {
      promptAction.showToast({ message: '请先登录后创建会话' });
      return;
    }

    // 2. 构建请求参数
    const createParams: CreateSessionParams = {
      title: '我的AI对话',
      modelName: 'qwen-turbo'
    };

    // 3. 调用创建会话接口
    promptAction.showToast({ message: '创建会话中...' });
    const result = await SessionApi.createSession(createParams);

    // 修改这里：直接判断 result，因为现在返回的是 SessionData 或 null
    console.log('创建会话返回结果:', result);
    if (result && result.id) {
      // 4. 创建成功，携带sessionId跳转到ChatPage
      console.log('新建会话ID:', result.id);
      const jumpParams: ChatPageParams = { sessionId: result.id };
      RouterModule.push(RouterMap.CHAT_PAGE, jumpParams, () => {
        console.log('从ChatPage返回，自动刷新列表');
        setTimeout(() => {
          this.manualRefresh();
        }, 300)
      });
    } else {
      console.error('创建会话失败，result:', result);
      promptAction.showToast({ message: '创建会话失败，请重试' });
    }
  }

  // 手动刷新方法
  private async manualRefresh() {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    await this.loadSessionList();
  }

  // 根据会话ID生成头像光圈颜色的方法
  private getAvatarCircleColor(sessionId: number): string {
    // 定义颜色池（可根据需要扩展）
    const colorPool = [
      '#337EFF', // 蓝色（默认）
      '#00C48C', // 绿色（3的倍数）
      '#FF7D00', // 橙色（4的倍数）
      '#FF4D4F', // 红色（5的倍数）
      '#9C6AFF', // 紫色（同时是3和4的倍数）
      '#FF67A7', // 粉色（同时是4和5的倍数）
      '#FFC107',// 黄色（同时是3和5的倍数）
    ];

    // 按ID规则分配颜色
    if (sessionId % 3 === 0 && sessionId % 4 === 0 && sessionId % 5 === 0) {
      return colorPool[6]; // 黄色（3、4、5公倍数）
    } else if (sessionId % 4 === 0 && sessionId % 5 === 0) {
      return colorPool[5]; // 粉色（4和5公倍数）
    } else if (sessionId % 3 === 0 && sessionId % 4 === 0) {
      return colorPool[4]; // 紫色（3和4公倍数）
    } else if (sessionId % 5 === 0) {
      return colorPool[3]; // 红色（5的倍数）
    } else if (sessionId % 4 === 0) {
      return colorPool[2]; // 橙色（4的倍数）
    } else if (sessionId % 3 === 0) {
      return colorPool[1]; // 绿色（3的倍数）
    } else {
      // 非特殊倍数：随机选择基础颜色（或固定蓝色）
      // 如需完全随机：return `#${Math.floor(Math.random()*16777215).toString(16)}`;
      return colorPool[0]; // 蓝色（默认）
    }
  }
}