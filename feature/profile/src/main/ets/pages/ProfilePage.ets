import { RouterModule, RouterMap } from 'basic';
import { UserInfo, SettingItem, EditProfileParams } from '../types/Types';
import { DEFAULT_USER_INFO, SETTING_ITEMS } from '../constants/data';

@Builder
export function ProfilePageBuilder() {
  ProfilePage()
}

@Entry
@Component
export struct ProfilePage {
  @State userInfo: UserInfo = DEFAULT_USER_INFO;
  @State settingItems: SettingItem[] = SETTING_ITEMS;

  build() {
    Column() {
      // 主内容区域
      Scroll() {
        Column({ space: 12 }) {
          // 用户信息卡片
          this.buildUserInfoCard()

          // 设置项列表
          this.buildSettingsList()

          // 退出登录按钮（无图标，独立区域）
          this.buildLogoutBtn()
        }
        .padding({ top: 20 })
      }
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 用户信息卡片
  @Builder
  buildUserInfoCard() {
    Column({ space: 16 }) {
      // 头像和基本信息
      Row({ space: 12 }) {
        // 头像
        Image($r(this.userInfo.avatar))
          .width(64)
          .height(64)
          .borderRadius(32)
          .border({ width: 2, color: '#FFFFFF' })

        // 用户信息
        Column({ space: 4 }) {
          Text(this.userInfo.name)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')

          Text(`学号：${this.userInfo.studentId}`)
            .fontSize(14)
            .fontColor('#666666')

          Text(`${this.userInfo.college} · ${this.userInfo.role}`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 编辑按钮
        Button('编辑资料', { type: ButtonType.Normal })
          .height(32)
          .fontSize(12)
          .borderRadius(16)
          .backgroundColor('#1890FF')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.navigateToEditProfile();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .padding({ top: 20, bottom: 20 })
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 12 })
  }

  // 设置项列表
  @Builder
  buildSettingsList() {
    Column() {
      ForEach(this.settingItems, (item: SettingItem) => {
        this.buildSettingItem(item)
      })
    }
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12 })
  }

  // 单个设置项
  @Builder
  buildSettingItem(item: SettingItem) {
    Column() {
      Row() {
        // 图标
        Image($r(item.icon))
          .width(24)
          .height(24)
          .margin({ right: 12 })

        // 标题
        Text(item.title)
          .fontSize(16)
          .fontColor('#000000')
          .layoutWeight(1)

        // 右侧内容
        if (item.type === 'navigation') {
          Image($r('app.media.ic_arrow_right'))
            .width(16)
            .height(16)
            .opacity(0.5)
        } else if (item.type === 'toggle') {
          Toggle({ type: ToggleType.Switch, isOn: item.value || false })
            .onChange((value: boolean) => {
              this.onSettingToggle(item.id, value);
            })
        } else if (item.type === 'logout') {
          // 退出登录项特殊样式
          Text('')
            .fontSize(16)
        }
      }
      .padding({
        left: 16,
        right: 16,
        top: 14,
        bottom: 14
      })
      .width('100%')
      .onClick(() => {
        this.onSettingItemClick(item);
      })

      // 分隔线（最后一项不显示）
      if (item.id !== this.settingItems[this.settingItems.length - 1].id) {
        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 52, right: 16 })
      }
    }
  }

  @Builder
  buildLogoutBtn(): void {
    Column() {
      Button('退出登录', { type: ButtonType.Normal })
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor('#FF4B4B')
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .onClick(() => this.showLogoutConfirm())
    }
    .padding({ left: 12, right: 12 })   // 与上面列表保持左右边距一致
    .margin({ top: 8 })
  }

  // ============ 业务方法 ============

  // 跳转到编辑资料
  private navigateToEditProfile(): void {
    RouterModule.push(RouterMap.EDIT_PROFILE_PAGE, {
      userInfo: this.userInfo
    } as EditProfileParams); // 添加类型断言
  }

  // 设置项点击处理
  private onSettingItemClick(item: SettingItem): void {
    switch (item.type) {
      case 'navigation':
        if (item.route) {
          // 根据route映射到对应的RouterMap
          const routeMap: Record<string, RouterMap> = {
            'AccountSettingsPage': RouterMap.ACCOUNT_SETTINGS_PAGE,
            'NotificationSettingsPage': RouterMap.NOTIFICATION_SETTINGS_PAGE,
            'GeneralSettingsPage': RouterMap.GENERAL_SETTINGS_PAGE,
            'AboutPage': RouterMap.ABOUT_PAGE
          };

          const targetRoute = routeMap[item.route] || RouterMap.PROFILE_PAGE;
          RouterModule.push(targetRoute);
        }
        break;
      case 'logout':
        this.showLogoutConfirm();
        break;
    }
  }

  // 开关切换处理（修复展开运算符问题）
  private onSettingToggle(id: number, value: boolean): void {
    this.settingItems = this.settingItems.map(item => {
      if (item.id === id) {
        return {
          id: item.id,
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          type: item.type,
          route: item.route,
          value: value  // 更新这个属性
        } as SettingItem; // 使用类型断言
      }
      return item;
    });
  }

  // 显示退出登录确认对话框
  private showLogoutConfirm(): void {
    // 这里可以调用系统的 AlertDialog 组件
    // 或者使用自定义的对话框
    console.log('退出登录');
    // 实际项目中应该调用退出登录的 API
  }
}