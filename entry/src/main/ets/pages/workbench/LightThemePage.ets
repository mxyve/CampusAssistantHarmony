import { LayoutFull } from '@hmos/ui-base';

@Component
export struct LightThemePage {
  @Consume('pageInfos') pageInfos: NavPathStack;

  @Builder
  buildPageContent() {
    Column() {
      Text('浅色主题页面')
        .fontSize(24)
        .fontColor('#333333')
        .margin({ bottom: 16 })

      Text('系统栏文字会自动变为黑色')
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    NavDestination() {
      Column() {
        LayoutFull({
          customBgColor: '#ffc0dcef',
          buildContent: this.buildPageContent
        })
      }
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}