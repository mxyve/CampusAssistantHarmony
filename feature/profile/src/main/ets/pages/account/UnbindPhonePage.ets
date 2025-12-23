import { RouterModule, RouterMap } from 'basic';

@Builder
export function UnbindPhonePageBuilder() {
  UnbindPhonePage()
}


@Component
export struct UnbindPhonePage {
  @State title: string = '全部功能';

  build() {
    NavDestination() {
      Column() {
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        Text('这里是所有快捷功能列表')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 10 })

        Text('（页面内容待完善）')
          .fontSize(14)
          .fontColor('#999999')

        Button('返回')
          .margin({ top: 30 })
          .width('60%')
          .onClick(() => {
            RouterModule.pop();
          })
      }
      .width('100%')
      .height('100%')
      .padding(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F5F5F5')
    }.title(this.title)
  }
}