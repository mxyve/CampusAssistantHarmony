import { RouterModule, RouterMap } from 'basic';
import { AuthApi } from '../api/AuthApi';
import { UserApi } from '../api/UserApi'; // 导入UserApi
import { storageUtil } from 'storage';
import promptAction from '@ohos.promptAction';
import { TokenVO, LoginDTO, SmsDTO } from '../types/AuthType';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Logger } from '@hmos/logger-kit';

@Builder
export function LoginPageBuilder() {
  LoginPage()
}

@Entry
@Component
export struct LoginPage {
  // 基础状态
  @State username: string = '';
  @State password: string = '';
  @State loading: boolean = false;
  @State showPassword: boolean = false;
  // 短信登录相关状态
  @State loginType: 'password' | 'sms' = 'password';
  @State mobile: string = '';
  @State smsCode: string = '';
  @State countdown: number = 0;
  @State canSendSms: boolean = true;
  private timer: number = -1;

  build() {
    NavDestination() {
      Column() {
        // 顶部安全区域
        Blank()
          .height(56)
          .backgroundColor('#FFFFFF')

        // 主内容区域
        Scroll() {
          Column({ space: 24 }) {
            // 标题区域
            this.buildHeader()

            // 登录方式切换栏
            this.buildLoginTypeSwitch()

            // 表单区域（根据登录类型切换）
            if (this.loginType === 'password') {
              this.buildPasswordForm()
            } else {
              this.buildSmsForm()
            }

            // 登录按钮
            this.buildLoginButton()
          }
          .padding({
            top: 40,
            left: 24,
            right: 24,
            bottom: 24
          })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)

        // 底部安全区域
        Blank()
          .height(48)
          .backgroundColor('#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
  }

  // ============ UI构建方法 ============

  @Builder
  buildHeader() {
    Column({ space: 16 }) {
      Text('智慧校园助手')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#000000')
        .textAlign(TextAlign.Center)

      Text(this.loginType === 'password' ? '欢迎回来，请登录您的账号' : '短信快捷登录')
        .fontSize(16)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  @Builder
  buildLoginTypeSwitch() {
    Row({ space: 12 }) {
      Button('账号密码登录', { type: ButtonType.Normal })
        .width('50%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .borderRadius(8)
        .backgroundColor(this.loginType === 'password' ? '#1890FF' : '#F5F5F5')
        .fontColor(this.loginType === 'password' ? '#FFFFFF' : '#333333')
        .enabled(!this.loading)
        .onClick(() => {
          this.loginType = 'password';
          this.countdown = 0;
          this.canSendSms = true;
          if (this.timer !== -1) {
            clearInterval(this.timer);
            this.timer = -1;
          }
        })

      Button('短信验证码登录', { type: ButtonType.Normal })
        .width('50%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .borderRadius(8)
        .backgroundColor(this.loginType === 'sms' ? '#1890FF' : '#F5F5F5')
        .fontColor(this.loginType === 'sms' ? '#FFFFFF' : '#333333')
        .enabled(!this.loading)
        .onClick(() => {
          this.loginType = 'sms';
          this.showPassword = false;
        })
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  @Builder
  buildPasswordForm() {
    Column({ space: 20 }) {
      Column({ space: 8 }) {
        Text('用户名')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .textAlign(TextAlign.Start)

        TextInput({ placeholder: '请输入学号/工号', text: this.username })
          .width('100%')
          .height(56)
          .fontSize(16)
          .borderRadius(12)
          .backgroundColor('#F5F5F5')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.username = value;
          })
      }

      Column({ space: 8 }) {
        Row() {
          Text('密码')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          TextInput({
            placeholder: '请输入密码',
            text: this.password
          })
            .width('100%')
            .height(56)
            .fontSize(16)
            .type(this.showPassword ? InputType.Normal : InputType.Password)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .padding({ left: 16, right: 16 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.password = value;
            })
        }
        .alignItems(VerticalAlign.Center)
      }
    }
  }

  @Builder
  buildSmsForm() {
    Column({ space: 20 }) {
      Column({ space: 8 }) {
        Text('手机号')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .textAlign(TextAlign.Start)

        TextInput({ placeholder: '请输入手机号', text: this.mobile })
          .width('100%')
          .height(56)
          .fontSize(16)
          .borderRadius(12)
          .backgroundColor('#F5F5F5')
          .padding({ left: 16, right: 16 })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .onChange((value: string) => {
            this.mobile = value;
          })
      }

      Column({ space: 8 }) {
        Text('验证码')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .textAlign(TextAlign.Start)

        Row() {
          TextInput({ placeholder: '请输入6位验证码', text: this.smsCode })
            .width('100%')
            .height(56)
            .fontSize(16)
            .borderRadius(12)
            .backgroundColor('#F5F5F5')
            .padding({ left: 16, right: 16 })
            .layoutWeight(1)
            .type(InputType.Number)
            .maxLength(6)
            .onChange((value: string) => {
              this.smsCode = value;
            })

          Button(this.countdown > 0 ? `${this.countdown}秒后重试` : '获取验证码')
            .width(120)
            .height(56)
            .fontSize(14)
            .borderRadius(12)
            .backgroundColor('#1890FF')
            .fontColor('#FFFFFF')
            .margin({ left: 12 })
            .enabled(this.canSendSms && this.mobile.length === 11 && !this.loading)
            .onClick(() => {
              this.sendSmsCode();
            })
        }
        .alignItems(VerticalAlign.Center)
      }
    }
  }

  @Builder
  buildLoginButton() {
    Column({ space: 16 }) {
      Button('登录', { type: ButtonType.Normal })
        .width('100%')
        .height(56)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .borderRadius(12)
        .backgroundColor('#1890FF')
        .fontColor('#FFFFFF')
        .enabled(!this.loading && this.getLoginButtonEnabledStatus())
        .onClick(() => {
          this.doLogin();
        })

      if (this.loading) {
        LoadingProgress()
          .color('#1890FF')
          .width(32)
          .height(32)
      }
    }
    .width('100%')
    .margin({ top: 20 })
  }

  // ============ 业务逻辑方法 ============

  private getLoginButtonEnabledStatus(): boolean {
    if (this.loginType === 'password') {
      return !!this.username.trim() && !!this.password.trim();
    } else {
      return !!this.mobile.trim() && !!this.smsCode.trim() && this.mobile.length === 11;
    }
  }

  // 修改doLogin方法，添加用户信息获取
  private async doLogin(): Promise<void> {
    if (this.loginType === 'password') {
      if (!this.username.trim() || !this.password.trim()) {
        this.showToast('请输入用户名和密码');
        return;
      }
    } else {
      if (!this.mobile.trim() || !this.smsCode.trim()) {
        this.showToast('请输入手机号和验证码');
        return;
      }
      const mobileReg = /^1[3-9]\d{9}$/;
      if (!mobileReg.test(this.mobile.trim())) {
        this.showToast('请输入正确的11位手机号');
        return;
      }
    }

    this.loading = true;

    try {
      let response: TokenVO | null = null;
      if (this.loginType === 'password') {
        const loginData: LoginDTO = {
          username: this.username.trim(),
          password: this.password.trim()
        };
        response = await AuthApi.passwordLogin(loginData) as TokenVO | null;
      } else {
        const smsData: SmsDTO = {
          mobile: this.mobile.trim(),
          code: this.smsCode.trim()
        };
        response = await AuthApi.smsLogin(smsData) as TokenVO | null;
        console.info('⭐response：', response)
      }

      if (response?.token) {
        // 保存token
        await storageUtil.set('token', response.token);
        console.info('✅ token 实际存储值：', await storageUtil.get('token'));
        console.info('✅ token 已写入：', response.token)

        // 获取用户信息
        const userInfo = await UserApi.getUserInfo();
        if (userInfo) {
          await storageUtil.setObject('userInfo', userInfo);
          console.log('🎈 userInfo 已写入：', userInfo)
          AppStorage.setOrCreate('currentUserInfo', userInfo);
        }

        // 更新全局登录状态
        AppStorage.setOrCreate('isLoggedIn', true);

        hilog.info(0x0000, 'LoginPage', `登录成功，用户信息: ${JSON.stringify(userInfo)}`);
        this.showToast('登录成功');

        // 延迟跳转，确保状态已更新
        setTimeout(() => {
          this.loading = false;
          this.navigateAfterLogin();
        }, 500);
      } else {
        this.loading = false;
        this.showToast(this.loginType === 'password'
          ? '登录失败，请检查用户名和密码'
          : '登录失败，请检查验证码是否正确');
      }
    } catch (error) {
      this.loading = false;
      hilog.error(0x0000, 'LoginPage', `登录异常: ${JSON.stringify(error)}`);

      let errorMessage = '登录失败，请重试';
      if (error?.response?.data?.message) {
        errorMessage = error.response.data.message;
      } else if (error?.message) {
        errorMessage = error.message;
      }
      this.showToast(errorMessage);
    }
  }

  // 发送短信验证码
  private async sendSmsCode(): Promise<void> {
    const mobileReg = /^1[3-9]\d{9}$/;
    if (!mobileReg.test(this.mobile.trim())) {
      this.showToast('请输入正确的11位手机号');
      return;
    }

    this.loading = true;
    try {
      const result = await AuthApi.sendSmsCode(this.mobile.trim());
      if (result !== null) {
        this.showToast(result ? `验证码发送成功: ${result}` : '验证码发送成功');
        this.startCountdown();
      } else {
        this.showToast('验证码发送失败');
      }
    } catch (error) {
      hilog.error(0x0000, 'LoginPage', `发送验证码异常: ${JSON.stringify(error)}`);
      this.showToast('验证码发送失败，请重试');
    } finally {
      this.loading = false;
    }
  }

  private startCountdown(): void {
    this.countdown = 60;
    this.canSendSms = false;

    if (this.timer !== -1) {
      clearInterval(this.timer);
    }

    this.timer = setInterval(() => {
      if (this.countdown > 0) {
        this.countdown--;
      } else {
        this.canSendSms = true;
        clearInterval(this.timer);
        this.timer = -1;
      }
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  // 登录成功后导航 - 添加返回之前的页面逻辑
  private navigateAfterLogin(): void {
    // 获取登录前的页面索引
    const beforeLoginPageIndex = AppStorage.get<number>('beforeLoginPageIndex') || 0;
    hilog.info(0x0000, 'LoginPage', `登录前页面索引: ${beforeLoginPageIndex}`);

    RouterModule.replace(RouterMap.HOME_PAGE);
    if (beforeLoginPageIndex > 0) {
      // 设置当前 Tab 索引
      AppStorage.setOrCreate('currentTabIndex', beforeLoginPageIndex);
      // 清除保存的索引
      AppStorage.setOrCreate('beforeLoginPageIndex', 0);
      hilog.info(0x0000, 'LoginPage', '返回之前的 Tab 页面');
      RouterModule.pop(); // 返回上一页（登录页）
    } else {
      hilog.info(0x0000, 'LoginPage', '跳转到首页');
      RouterModule.replace(RouterMap.HOME_PAGE);
    }
  }

  private showToast(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
}