import { Index } from "./Index"

/* ========== 数据接口 ========== */
interface TabItem {
  name: string;
  normalIcon: Resource;
  selectedIcon: Resource;
}

interface WorkbenchItem {
  id: number;
  name: string;
  pageName: string;
}

interface ProfileItem {
  id: number;
  name: string;
  pageName: string;
}

/* ========== 首页组件 ========== */
@Component
export struct HomePage {
  @State currentIndex: number = 0;
  @Consume('pageInfos') pageInfos: NavPathStack;
  /* ---- 底部导航数据 ---- */
  private tabsData: TabItem[] = [
    {
      name: '首页',
      normalIcon: $r('app.media.nav_component_normal'),
      selectedIcon: $r('app.media.nav_component_selected')
    },
    {
      name: '对话',
      normalIcon: $r('app.media.nav_chat_normal'),
      selectedIcon: $r('app.media.nav_chat_selected')
    },
    {
      name: '工作台',
      normalIcon: $r('app.media.nav_workbench_normal'),
      selectedIcon: $r('app.media.nav_workbench_selected')
    },
    {
      name: '我的',
      normalIcon: $r('app.media.nav_home_normal'),
      selectedIcon: $r('app.media.nav_home_selected')
    }
  ];
  /* ---- 组件列表数据 ---- */
  private workbenchItem: WorkbenchItem[] = [
    { id: 1, name: '浅色主题页', pageName: 'LightThemePage' },
  ];
  private profileItem: ProfileItem[] = [
    { id: 1, name: 'item_profile', pageName: 'ProfilePage' }
  ];

  build() {
    // Tabs与TabContent使用
    Tabs({
      index: this.currentIndex,
      controller: new TabsController()
    }) {
      /* 首页 */
      TabContent() {
        Index() // 这里使用导入的Index组件作为首页内容
      }
      .tabBar(this.TabBuilder(0))

      /* 对话 */
      TabContent() {
        this.ChatTab()
      }
      .tabBar(this.TabBuilder(1))

      /* 工作台 Tab */
      TabContent() {
        this.WorkbenchTab()
      }
      .tabBar(this.TabBuilder(1))

      /* 我的 Tab */
      TabContent() {
        this.ProfileTab()
      }
      .tabBar(this.TabBuilder(2))

    }
    .barPosition(BarPosition.End)
    .onChange(idx => this.currentIndex = idx)
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }

  /* ---------------- 对话 Tab ---------------- */
  @Builder
  ChatTab() {
    List({ space: 12 }) {
      ForEach(this.workbenchItem, (item: WorkbenchItem) => {
        ListItem() {
          Text(item.name)
            .width('100%')
            .height(72)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.pageInfos.pushPath({ name: item.pageName });
            });
        }
      }, (item: WorkbenchItem) => item.id.toString());
    }
    .width('90%')
    .margin({ top: 12 });
  }

  /* ---------------- 工作台 Tab ---------------- */
  @Builder
  WorkbenchTab() {
    List({ space: 12 }) {
      ForEach(this.workbenchItem, (item: WorkbenchItem) => {
        ListItem() {
          Text(item.name)
            .width('100%')
            .height(72)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.pageInfos.pushPath({ name: item.pageName });
            });
        }
      }, (item: WorkbenchItem) => item.id.toString());
    }
    .width('90%')
    .margin({ top: 12 });
  }

  /* ---------------- 我的 Tab ---------------- */
  @Builder
  ProfileTab() {
    List({ space: 12 }) {
      ForEach(this.profileItem, (item: ProfileItem) => {
        ListItem() {
          Text(item.name)
            .width('100%')
            .height(72)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              // 点击跳转到对应的页面
              this.pageInfos.pushPath({ name: item.pageName });
            });
        }
      }, (item: ProfileItem) => item.id.toString()); // 用id作为唯一标识
    }
    .width('90%')
    .margin({ top: 12 })
    .backgroundColor('#F5F5F5');
  }

  /* ---------------- 底部导航栏 Builder ---------------- */
  @Builder
  TabBuilder(index: number) {
    Column() {
      Image(this.currentIndex === index
        ? this.tabsData[index].selectedIcon
        : this.tabsData[index].normalIcon)
        .size({ width: 24, height: 24 });

      Text(this.tabsData[index].name)
        .fontSize(12)
        .margin({ top: 4 })
        .fontColor(this.currentIndex === index ? '#1296db' : Color.Gray);
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center);
  }
}