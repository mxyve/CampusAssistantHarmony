import {
  QuickFunction, CampusNotification, CampusNews
} from '../types/Types';
import {
  QUICK_FUNCTIONS, CAMPUS_NOTIFICATIONS, CAMPUS_NEWS
} from '../constants/data';

import { RouterModule, RouterMap } from 'basic';

import router from '@ohos.router';

@Builder
export function HomePageBuilder() {
  HomePage()
}

@Entry
@Component
export struct HomePage {
  // 使用类型化的状态
  @State quickFunctions: QuickFunction[] = QUICK_FUNCTIONS;
  @State notifications: CampusNotification[] = CAMPUS_NOTIFICATIONS;
  @State campusNews: CampusNews[] = CAMPUS_NEWS;

  // 构建函数
  build() {
    Column() {
      // 顶部标题栏
      this.buildHeader()

      // 内容区域
      Scroll() {
        Column({ space: 20 }) {
          // 快捷功能区域
          this.buildQuickFunctions()

          // 校园通知区域
          this.buildNotifications()

          // 校园动态区域
          this.buildCampusNews()
        }
        .padding(16)
        .width('100%')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 顶部标题栏
  @Builder
  buildHeader() {
    Row() {
      Column() {
        Text('智慧校园助手')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
        Text('Welcome back!')
          .fontSize(14)
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_default_avatar'))
        .width(24)
        .height(24)
        .margin({ right: 16 })
        .onClick(() => {
          this.navigateToNotificationCenter();
        })
    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor('#FFFFFF')
    .width('100%')
    .height(60)
  }

  // 快捷功能区域
  @Builder
  buildQuickFunctions() {
    Column() {
      Row() {
        Text('快捷功能')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
        Blank()
        Text('全部')
          .fontSize(14)
          .fontColor('#1890FF')
          .onClick(() => {
            this.navigateToAllFunctions();
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      Grid() {
        ForEach(this.quickFunctions, (item: QuickFunction) => {
          GridItem() {
            Column({ space: 8 }) {
              Image($r(item.icon))
                .width(40)
                .height(40)
              Text(item.title)
                .fontSize(12)
                .fontColor('#333333')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .onClick(() => {
              this.navigateToPage(item.pageUrl);
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
    }
  }

  // 校园通知区域
  @Builder
  buildNotifications() {
    Column() {
      Row() {
        Text('校园通知')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
        Blank()
        Text('更多')
          .fontSize(14)
          .fontColor('#1890FF')
          .onClick(() => {
            this.navigateToNotificationList();
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      Column({ space: 12 }) {
        ForEach(this.notifications, (item: CampusNotification) => {
          this.buildNotificationItem(item)
        })
      }
    }
  }

  // 单个通知项 - 使用类型参数
  @Builder
  buildNotificationItem(item: CampusNotification) {
    Column({ space: 8 }) {
      Row() {
        // 未读红点
        if (item.unread) {
          Circle({ width: 8, height: 8 })
            .fill('#FF4D4F')
            .margin({ right: 8 })
        }

        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(item.unread ? '#000000' : '#666666')
          .layoutWeight(1)

        Text(item.time)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')

      Text(item.content)
        .fontSize(14)
        .fontColor('#666666')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.viewNotificationDetail(item);
    })
  }

  // 校园动态区域
  @Builder
  buildCampusNews() {
    Column() {
      Row() {
        Text('校园动态')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')
        Blank()
        Text('更多')
          .fontSize(14)
          .fontColor('#1890FF')
          .onClick(() => {
            this.navigateToNewsList();
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      Column({ space: 12 }) {
        ForEach(this.campusNews, (item: CampusNews) => {
          this.buildNewsItem(item)
        })
      }
    }
  }

  // 单个动态项 - 使用类型参数
  @Builder
  buildNewsItem(item: CampusNews) {
    Column({ space: 12 }) {
      // 图片
      Image($r(item.image))
        .width('100%')
        .height(160)
        .objectFit(ImageFit.Cover)
        .borderRadius(12)

      // 内容
      Column({ space: 8 }) {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#000000')

        Text(item.content)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 可选标签展示
        if (item.tags && item.tags.length > 0) {
          Row({ space: 8 }) {
            ForEach(item.tags, (tag: string) => {
              Text(`#${tag}`)
                .fontSize(12)
                .fontColor('#1890FF')
                .padding({
                  left: 8,
                  right: 8,
                  top: 2,
                  bottom: 2
                })
                .backgroundColor('#E6F7FF')
                .borderRadius(4)
            })
          }
          .margin({ top: 8 })
        }
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.viewNewsDetail(item);
    })
  }

  // ============ 业务方法 ============

  /**
   * 查看通知详情
   */
  private viewNotificationDetail(notification: CampusNotification): void {
    // 标记为已读
    this.markNotificationAsRead(notification.id);

    // 跳转到详情页
    router.pushUrl({
      url: 'pages/NotificationDetailPage',
      params: { notificationId: notification.id }
    });
  }

  /**
   * 查看动态详情
   */
  private viewNewsDetail(news: CampusNews): void {
    router.pushUrl({
      url: 'pages/NewsDetailPage',
      params: { newsId: news.id }
    });
  }

  /**
   * 标记通知为已读
   */
  private markNotificationAsRead(id: number): void {
    this.notifications = this.notifications.map(item => {
      if (item.id === id) {
        // 手动创建新对象
        return {
          id: item.id,
          type: item.type,
          title: item.title,
          time: item.time,
          content: item.content,
          unread: false, // 修改这个属性
          source: item.source,
          priority: item.priority
        } as CampusNotification;
      }
      return item;
    });
  }

  /**
   * 页面跳转
   */
  private navigateToPage(pageUrl: string): void {
    router.pushUrl({ url: pageUrl })
      .catch((err: Error) => {
        console.error(`Navigate to ${pageUrl} failed: ${err.message}`);
      });
  }

  /**
   * 跳转到通知中心
   */
  private navigateToNotificationCenter(): void {
    this.navigateToPage('pages/NotificationCenterPage');
  }

  /**
   * 跳转到通知列表
   */
  private navigateToNotificationList(): void {
    RouterModule.push(RouterMap.NOTIFICATION_LIST);
  }

  /**
   * 跳转到动态列表
   */
  private navigateToNewsList(): void {
    RouterModule.push(RouterMap.NEWS_LIST);
  }

  /**
   * 跳转到全部功能
   */
  private navigateToAllFunctions(): void {
    RouterModule.push(RouterMap.ALL_FUNCTIONS);
  }
}