import { RouterModule, RouterMap } from 'basic';
import { AuthApi } from '../../api/AuthApi';
import { ResetPasswordDTO } from '../../types/AuthType';
import prompt from '@ohos.prompt';
import { storageUtil } from 'storage'; // 新增：导入存储工具
import { UserInfo } from '../../types/Types'; // 需要导入UserInfo类型

@Builder
export function PasswordSettingsPageBuilder() {
  PasswordSettingsPage()
}

@Component
export struct PasswordSettingsPage {
  @State mobile: string = ''; // 从用户信息中读取
  @State code: string = '';
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State codeBtnText: string = '获取验证码';
  @State codeBtnDisabled: boolean = false;
  private countDownTimer: number | null = null;

  // 新增：组件生命周期方法
  aboutToAppear() {
    this.loadUserMobile();
  }

  // 新增：从存储中加载用户手机号
  private async loadUserMobile() {
    try {
      // 方式1：从AppStorage中获取（如果已经设置了全局状态）
      // this.mobile = AppStorage.get('currentUserInfo')?.mobile || '';

      // 方式2：直接从本地存储中读取用户信息
      const userInfo = await storageUtil.getObject<UserInfo>('userInfo');
      if (userInfo?.mobile) {
        this.mobile = userInfo.mobile;
      } else {
        // 如果没有手机号，提示用户需要先绑定手机号
        prompt.showToast({ message: '未找到手机号，请先绑定手机' });
        // 可以考虑跳转到绑定手机页面
        // RouterModule.push(RouterMap.BIND_MOBILE_PAGE);
      }
    } catch (e) {
      console.error('加载用户手机号失败', e);
    }
  }

  // 表单校验 - 修改：移除手机号格式校验（因为是从用户信息读取的）
  private validateForm(): boolean {
    // 手机号验证改为只需要检查是否为空
    if (!this.mobile) {
      prompt.showToast({ message: '未找到手机号，请先绑定手机' });
      return false;
    }

    if (!/^\d{4}$/.test(this.code)) {
      prompt.showToast({ message: '请输入4位数字验证码' });
      return false;
    }
    if (!/^\d{6,12}$/.test(this.newPassword)) {
      prompt.showToast({ message: '密码需6-12位' });
      return false;
    }
    if (this.newPassword !== this.confirmPassword) {
      prompt.showToast({ message: '两次输入的密码不一致' });
      return false;
    }
    return true;
  }

  // 获取短信验证码 - 修改：移除手机号格式校验（因为是从用户信息读取的）
  async getSmsCode() {
    // 只需要检查手机号是否为空
    if (!this.mobile) {
      prompt.showToast({ message: '未找到手机号，请先绑定手机' });
      return;
    }

    this.codeBtnDisabled = true;
    this.codeBtnText = '60s后重新获取';

    const result = await AuthApi.sendSmsCode(this.mobile);
    if (!result) {
      prompt.showToast({ message: '验证码发送失败' });
      this.resetCodeBtn();
      return;
    }

    let count = 60;
    this.countDownTimer = setInterval(() => {
      count--;
      this.codeBtnText = `${count}s后重新获取`;
      if (count <= 0) {
        this.resetCodeBtn();
      }
    }, 1000);
  }

  private resetCodeBtn() {
    if (this.countDownTimer) {
      clearInterval(this.countDownTimer);
      this.countDownTimer = null;
    }
    this.codeBtnDisabled = false;
    this.codeBtnText = '获取验证码';
  }

  // 提交设置密码
  async submitPassword() {
    if (!this.validateForm()) {
      return;
    }

    const result = await AuthApi.resetPassword({
      mobile: this.mobile,
      code: this.code,
      newPassword: this.newPassword
    });

    if (result?.includes('成功')) {
      prompt.showToast({ message: result });
      RouterModule.push(RouterMap.LOGIN_PAGE);
    } else {
      prompt.showToast({ message: result || '密码设置失败' });
    }
  }

  aboutToDisappear() {
    if (this.countDownTimer) {
      clearInterval(this.countDownTimer);
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 修改：将手机号输入框改为只读的文本显示
        Column() {
          Text('手机号')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 4 })

          // 显示手机号，不可编辑
          Row() {
            Text(this.mobile || '未绑定手机')
              .fontSize(16)
              .fontColor(this.mobile ? '#000000' : '#999999')
              .layoutWeight(1)

            // 如果手机号为空，可以添加绑定按钮
            if (!this.mobile) {
              Button('去绑定', { type: ButtonType.Capsule })
                .fontSize(12)
                .height(28)
                .onClick(() => {
                  // 跳转到绑定手机页面
                  // RouterModule.push(RouterMap.BIND_MOBILE_PAGE);
                  prompt.showToast({ message: '请先到个人资料中绑定手机号' });
                })
            }
          }
          .padding(15)
          .backgroundColor(Color.White)
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 15 })

        // 验证码行
        Row() {
          TextInput({ placeholder: '请输入4位验证码' })
            .type(InputType.Number)
            .maxLength(4)
            .backgroundColor(Color.White)
            .padding(15)
            .flexGrow(1)
            .onChange((value) => this.code = value)

          Button(this.codeBtnText)
            .width(120)
            .height('100%')
            .backgroundColor(this.codeBtnDisabled ? '#CCCCCC' : '#007DFF')
            .fontColor(Color.White)
            .enabled(!this.codeBtnDisabled && !!this.mobile) // 手机号为空时禁用
            .onClick(() => this.getSmsCode())
        }
        .width('100%')
        .height(50)
        .margin({ bottom: 15 })

        // 新密码输入
        TextInput({ placeholder: '请输入新密码（6-12位）' })
          .type(InputType.Password)
          .backgroundColor(Color.White)
          .padding(15)
          .width('100%')
          .margin({ bottom: 15 })
          .onChange((value) => this.newPassword = value)

        TextInput({ placeholder: '请再次输入密码' })
          .type(InputType.Password)
          .backgroundColor(Color.White)
          .padding(15)
          .width('100%')
          .margin({ bottom: 20 })
          .onChange((value) => this.confirmPassword = value)

        // 提交按钮
        Button('确认设置')
          .width('100%')
          .height(50)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .borderRadius(8)
          .enabled(!!this.mobile) // 手机号为空时禁用
          .onClick(() => this.submitPassword())
      }
      .padding(20)
      .backgroundColor('#F5F5F5')
    }
    .title('密码设置')
  }
}