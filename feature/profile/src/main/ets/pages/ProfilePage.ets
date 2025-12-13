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
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false; // 监听登录状态
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null;

  aboutToAppear() {
    this.restoreLoginState();
  }

  // 恢复登录状态（核心）
  private async restoreLoginState() {
    try {
      // 1. 先从本地读 token
      const token = await storageUtil.get('token');
      if (!token) {
        // 无 token → 标记为未登录
        this.isLoggedIn = false;
        AppStorage.setOrCreate('isLoggedIn', false);
        AppStorage.setOrCreate('currentUserInfo', null);
        return;
      }

      // 2. 有 token → 标记为已登录
      this.isLoggedIn = true;
      AppStorage.setOrCreate('isLoggedIn', true);

      // 3. 先从本地读用户信息（避免重复请求接口）
      const localUserInfo = await storageUtil.getObject<UserInfo>('userInfo');
      if (localUserInfo) {
        // 本地有用户信息 → 直接恢复到全局状态
        this.currentUserInfo = localUserInfo;
        AppStorage.setOrCreate('currentUserInfo', localUserInfo);
      } else {
        // 本地无用户信息 → 兜底请求接口
        await this.refreshUserInfo();
      }
    } catch (e) {
      console.error('恢复登录状态失败', e);
      // 异常时强制标记为未登录
      this.isLoggedIn = false;
      AppStorage.setOrCreate('isLoggedIn', false);
    }
  }

  /** 仅用于兜底/手动刷新 */
  private async refreshUserInfo() {
    try {
      const latest = await UserApi.getUserInfo(); // 带 token 的接口
      if (latest) {
        this.currentUserInfo = latest;
        AppStorage.setOrCreate('currentUserInfo', latest);
        await storageUtil.setObject('userInfo', latest); // 同时落盘
      }
    } catch (e) {
      console.error('刷新用户信息失败', e);
    }
  }

  build() {
    Column() {
      // 主内容区域
      Scroll() {
        Column({ space: 12 }) {
          if (this.isLoggedIn) {
            // 已登录状态：显示用户信息和设置
            this.buildLoggedInView()
          } else {
            // 未登录状态：显示登录提示
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
      // 用户信息卡片
      this.buildUserInfoCard()

      // 设置项列表
      this.buildSettingsList()

      // 退出登录按钮
      this.buildLogoutBtn()
    }
  }

  // 未登录视图
  @Builder
  buildLoggedOutView() {
    Column({ space: 20 }) {
      // 登录提示卡片
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
    // 只有currentUserInfo存在时才渲染
    if (this.currentUserInfo) {

      Column({ space: 16 }) {
        Row({ space: 12 }) {
          // 头像：优先用后端avatar，否则用默认图
          Image(this.currentUserInfo.avatar ? this.currentUserInfo.avatar : $r('app.media.ic_default_avatar'))
            .width(64)
            .height(64)
            .borderRadius(32)
            .border({ width: 2, color: '#FFFFFF' })

          Column({ space: 6 }) {
            // 昵称/用户名：优先显示nickname，否则显示username
            Text(this.currentUserInfo.nickname || this.currentUserInfo.username)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')

            // 邮箱：有则显示
            if (this.currentUserInfo.email) {
              Text(`邮箱：${this.currentUserInfo.email}`)
                .fontSize(14)
                .fontColor('#666666')
            }

            // 手机号：有则显示（注意后端可能返回null）
            if (this.currentUserInfo.mobile) {
              Text(`手机号：${this.currentUserInfo.mobile}`)
                .fontSize(14)
                .fontColor('#666666')
            }
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

  // 跳转到登录页面
  private navigateToLogin(): void {
    // 保存当前页面索引（如果需要在登录后返回）
    AppStorage.setOrCreate('beforeLoginPageIndex', 2); // ProfilePage 通常是第3个tab

    RouterModule.push(RouterMap.LOGIN_PAGE);
  }

  // 设置项点击处理
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

  // 开关切换处理
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

  // 显示退出登录确认对话框
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
      // 1. 清 token + 用户数据
      await storageUtil.delete('token');
      await storageUtil.delete('userInfo');
      await storageUtil.clear();

      // 2. 清全局状态（触发所有 @StorageLink 刷新）
      AppStorage.setOrCreate('isLoggedIn', false);
      AppStorage.setOrCreate('currentUserInfo', null);
      this.currentUserInfo = null;

      // 3. 提示 + 跳转
      promptAction.showToast({ message: '已退出登录', duration: 1500 });
      RouterModule.clear();
      RouterModule.push(RouterMap.LOGIN_PAGE)
    } catch (e) {
      console.error('退出失败', e);
      AppStorage.setOrCreate('isLoggedIn', false);
      AppStorage.setOrCreate('currentUserInfo', null);
    }
  }
}