// 新增导入 CommonNavBar
import { CommonNavBar, NavBarOptions } from '@hmos/common-nav-bar';
import { RouterModule, RouterMap } from 'basic';
import { UserInfo, SettingItem } from '../types/Types';
import { SETTING_ITEMS } from '../constants/data';
import { storageUtil } from 'storage';
import promptAction from '@ohos.promptAction';
import { UserApi } from '../api/UserApi';

@Builder
export function ProfilePageBuilder() {
  ProfilePage()
}

@Entry
@Component
export struct ProfilePage {
  @State settingItems: SettingItem[] = SETTING_ITEMS;
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null;
  // 导航栏配置
  @State navBarOptions: NavBarOptions = {
    title: '个人中心',
    showBack: false, // 在Tab页面中通常不显示返回按钮
    backgroundColor: '#FFFFFF',
    titleColor: '#000000'
  };

  aboutToAppear() {
    this.restoreLoginState();
  }

  // 恢复登录状态（保持不变）
  private async restoreLoginState() {
    try {
      const token = await storageUtil.get('token');
      if (!token) {
        this.isLoggedIn = false;
        AppStorage.setOrCreate('isLoggedIn', false);
        AppStorage.setOrCreate('currentUserInfo', null);
        return;
      }

      this.isLoggedIn = true;
      AppStorage.setOrCreate('isLoggedIn', true);

      const localUserInfo = await storageUtil.getObject<UserInfo>('userInfo');
      if (localUserInfo) {
        this.currentUserInfo = localUserInfo;
        AppStorage.setOrCreate('currentUserInfo', localUserInfo);
      } else {
        await this.refreshUserInfo();
      }
    } catch (e) {
      console.error('恢复登录状态失败', e);
      this.isLoggedIn = false;
      AppStorage.setOrCreate('isLoggedIn', false);
    }
  }

  private async refreshUserInfo() {
    try {
      const latest = await UserApi.getUserInfo();
      if (latest) {
        this.currentUserInfo = latest;
        AppStorage.setOrCreate('currentUserInfo', latest);
        await storageUtil.setObject('userInfo', latest);
      }
    } catch (e) {
      console.error('刷新用户信息失败', e);
    }
  }

  build() {
    Column() {
      // 使用 CommonNavBar 组件
      CommonNavBar({
        options: this.navBarOptions
      })

      // 主内容区域
      Scroll() {
        Column({ space: 12 }) {
          if (this.isLoggedIn) {
            this.buildLoggedInView()
          } else {
            this.buildLoggedOutView()
          }
        }
        .padding({ top: 20 })
      }
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 已登录视图
  @Builder
  buildLoggedInView() {
    Column({ space: 12 }) {
      this.buildUserInfoCard()
      this.buildSettingsList()
      this.buildLogoutBtn()
    }
  }

  // 未登录视图
  @Builder
  buildLoggedOutView() {
    Column({ space: 20 }) {
      Column() {
        Image($r('app.media.ic_default_avatar'))
          .width(80)
          .height(80)
          .borderRadius(40)
          .margin({ bottom: 16 })

        Text('您还未登录')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ bottom: 8 })

        Text('登录后享受更多功能')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 24 })

        Button('立即登录', { type: ButtonType.Normal })
          .width('60%')
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(22)
          .backgroundColor('#1890FF')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.navigateToLogin();
          })
      }
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 12, right: 12 })
      .alignItems(HorizontalAlign.Center)

      // 功能说明
      Column({ space: 16 }) {
        Row() {
          Image($r('app.media.avatar_img'))
            .width(24)
            .height(24)
            .margin({ right: 12 })
          Text('查看个人课表')
            .fontSize(16)
            .fontColor('#333333')
            .layoutWeight(1)
        }
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 12, right: 12 })
    }
  }

  // 用户信息卡片
  @Builder
  buildUserInfoCard() {
    if (this.currentUserInfo) {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Image(this.currentUserInfo.avatar ? this.currentUserInfo.avatar : $r('app.media.ic_default_avatar'))
            .width(64)
            .height(64)
            .borderRadius(32)
            .border({ width: 2, color: '#FFFFFF' })

          Column({ space: 6 }) {
            Text(this.currentUserInfo.nickname || this.currentUserInfo.username)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')

            if (this.currentUserInfo.email) {
              Text(`邮箱：${this.currentUserInfo.email}`)
                .fontSize(14)
                .fontColor('#666666')
            }

            if (this.currentUserInfo.mobile) {
              Text(`手机号：${this.currentUserInfo.mobile}`)
                .fontSize(14)
                .fontColor('#666666')
            }

            // 修改：将"编辑资料"按钮改为右上角设置图标
            // 这里不再放置编辑资料按钮
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .padding({ top: 20, bottom: 20 })
      .backgroundColor('#FFFFFF')
      .margin({ bottom: 12 })
    }
  }

  // 设置项列表（保持不变）
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

  // 单个设置项（保持不变）
  @Builder
  buildSettingItem(item: SettingItem) {
    Column() {
      Row() {
        Image($r(item.icon))
          .width(24)
          .height(24)
          .margin({ right: 12 })

        Text(item.title)
          .fontSize(16)
          .fontColor('#000000')
          .layoutWeight(1)

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

      if (item.id !== this.settingItems[this.settingItems.length - 1].id) {
        Divider()
          .strokeWidth(0.5)
          .color('#F0F0F0')
          .margin({ left: 52, right: 16 })
      }
    }
  }

  @Builder
  buildLogoutBtn() {
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
    .padding({ left: 12, right: 12 })
    .margin({ top: 8 })
  }

  // ============ 业务方法 ============

  // 如果需要在导航栏添加设置图标，可以这样修改配置：
  private updateNavBarForLoggedIn() {
    if (this.isLoggedIn) {
      this.navBarOptions = {
        title: this.navBarOptions.title,
        showBack: this.navBarOptions.showBack,
        backIcon: this.navBarOptions.backIcon,
        onBackClick: this.navBarOptions.onBackClick,
        backgroundColor: this.navBarOptions.backgroundColor,
        titleColor: this.navBarOptions.titleColor,
        divider: this.navBarOptions.divider,
        rightItems: [
          {
            type: 'icon',
            icon: $r('app.media.ic_arrow_right'),
            onClick: () => {
              // 跳转到设置页面或显示设置菜单
              RouterModule.push(RouterMap.EDIT_PROFILE_PAGE);
            },
            tintColor: '#000000'
          }
        ]
      };
    } else {
      this.navBarOptions = {
        title: this.navBarOptions.title,
        showBack: this.navBarOptions.showBack,
        backIcon: this.navBarOptions.backIcon,
        onBackClick: this.navBarOptions.onBackClick,
        backgroundColor: this.navBarOptions.backgroundColor,
        titleColor: this.navBarOptions.titleColor,
        divider: this.navBarOptions.divider,
        rightItems: undefined
      };
    }
  }

  // 在登录状态变化时更新导航栏
  aboutToUpdate() {
    // 监听登录状态变化，更新导航栏
    this.updateNavBarForLoggedIn();
  }

  // 跳转到登录页面
  private navigateToLogin(): void {
    AppStorage.setOrCreate('beforeLoginPageIndex', 2);
    RouterModule.push(RouterMap.LOGIN_PAGE);
  }

  // 设置项点击处理（保持不变）
  private onSettingItemClick(item: SettingItem): void {
    switch (item.type) {
      case 'navigation':
        if (item.route) {
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

  // 开关切换处理（保持不变）
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
          value: value
        } as SettingItem;
      }
      return item;
    });
  }

  // 显示退出登录确认对话框（保持不变）
  private showLogoutConfirm(): void {
    promptAction.showDialog({
      title: '提示',
      message: '确定要退出登录吗？',
      buttons: [
        {
          text: '取消',
          color: '#999999'
        },
        {
          text: '确定',
          color: '#FF4D4F'
        }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.performLogout();
      }
    }).catch((err: Error) => {
      console.error('显示对话框失败:', err);
    });
  }

  private async performLogout() {
    try {
      await storageUtil.delete('token');
      await storageUtil.delete('userInfo');
      await storageUtil.clear();

      AppStorage.setOrCreate('isLoggedIn', false);
      AppStorage.setOrCreate('currentUserInfo', null);
      this.currentUserInfo = null;

      promptAction.showToast({ message: '已退出登录', duration: 1500 });
      RouterModule.clear();
      RouterModule.push(RouterMap.LOGIN_PAGE);
    } catch (e) {
      console.error('退出失败', e);
      AppStorage.setOrCreate('isLoggedIn', false);
      AppStorage.setOrCreate('currentUserInfo', null);
    }
  }
}