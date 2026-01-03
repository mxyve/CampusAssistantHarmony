// components/CommonNavBar.ets
import { CommonNavBarRightBtn, NavBarTheme } from '../types/CommonTypes';

@Component
export struct CommonNavBar {
  /**
   * 必传参数：导航栏标题
   */
  @Prop title: string = '';
  /**
   * 可选参数：左侧返回按钮配置
   */
  @Prop showBackBtn: boolean = true; // 是否显示返回按钮
  @Prop backBtnClick: () => void = () => {
    // 默认返回逻辑：路由回退
    try {
      RouterModule.back();
    } catch (e) {
      console.warn('CommonNavBar: 已处于路由栈首页，无法返回');
    }
  };
  /**
   * 可选参数：右侧操作按钮（支持单个/多个）
   */
  @Prop rightBtns: CommonNavBarRightBtn[] = [];
  /**
   * 可选参数：导航栏主题（默认浅色）
   */
  @Prop theme: NavBarTheme = 'light';
  /**
   * 可选参数：自定义样式
   */
  @Prop navBarHeight: number = 48; // 导航栏高度
  @Prop customBgColor?: string; // 自定义背景色（优先级高于主题默认色）

  /**
   * 主题对应的默认样式
   */
  private get themeConfig() {
    return this.theme === 'light' ? {
      bgColor: '#FFFFFF',
      titleColor: '#000000',
      btnColor: '#3F6AF6'
    } : {
      bgColor: '#181818',
      titleColor: '#FFFFFF',
      btnColor: '#64B5F6'
    };
  }

  build() {
    Row() {
      // 左侧：返回按钮
      if (this.showBackBtn) {
        Image($r('app.media.nav_back'))
          .width(24)
          .height(24)
          .fillColor(this.customBgColor ? this.themeConfig.btnColor : this.customBgColor)
          .onClick(this.backBtnClick)
          .margin({ left: 16 });
      } else {
        Blank().width(16); // 占位，保证标题居中
      }

      // 中间：标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeConfig.titleColor)
        .textAlign(TextAlign.Center)
        .flexGrow(1); // 占满中间空间，实现居中

      // 右侧：操作按钮（支持多个）
      Row() {
        ForEach(this.rightBtns, (btn: CommonNavBarRightBtn) => {
          if (btn.type === 'icon') {
            Image(btn.content as Resource)
              .width(btn.iconSize || 24)
              .height(btn.iconSize || 24)
              .fillColor(this.themeConfig.btnColor)
              .onClick(btn.onClick)
              .margin({ left: btn.marginLeft || 12, right: btn.marginLeft ? 0 : 16 });
          } else {
            Text(btn.content as string)
              .fontSize(btn.fontSize || 14)
              .fontColor(this.themeConfig.btnColor)
              .onClick(btn.onClick)
              .margin({ left: btn.marginLeft || 12, right: btn.marginLeft ? 0 : 16 });
          }
        }, (_, index) => index.toString());
      }
    }
    .width('100%')
    .height(this.navBarHeight)
    .backgroundColor(this.customBgColor || this.themeConfig.bgColor)
    .alignItems(VerticalAlign.Center);
  }
}