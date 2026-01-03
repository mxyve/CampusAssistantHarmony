import { RouterModule, RouterMap } from 'basic';

interface SettingItem {
  name: string;
  route: RouterMap;
}

@Builder
export function AccountSettingsPageBuilder() {
  AccountSettingsPage()
}

@Component
export struct AccountSettingsPage {
  @State title: string = '账号设置';
  /* 数据模型 */
  @State settingList: SettingItem[] = [
    { name: '密码设置', route: RouterMap.PASSWORD_SETTINGS_PAGE },
    { name: '解绑手机', route: RouterMap.UNBIND_PHONE_PAGE }
  ];

  build() {
    NavDestination() {
      Column() {
        /* 顶部标题栏 */
        Row() {
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor('#000000')
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#FFFFFF')

        /* 列表区域 */
        List() {
          ForEach(this.settingList, (item: SettingItem) => {
            ListItem() {
              Row() {
                Text(item.name)
                  .fontSize(16)
                  .fontColor('#181818')
                  .layoutWeight(1)

                Image($r('app.media.ic_arrow_right'))
                  .width(16)
                  .height(16)
                  .fillColor('#B8B8B8')
              }
              .width('100%')
              .height(52)
              .padding({ left: 16, right: 16 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .onClick(() => {
                RouterModule.push(item.route); // ✅ 直接传字符串
              })
              .stateStyles({
                pressed: {
                  backgroundColor: '#F2F2F2'
                }
              })
            }
            .padding({
              left: 16,
              right: 16,
              top: 4,
              bottom: 4
            })
          }, (item: SettingItem) => item.name)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
        .listDirection(Axis.Vertical)
        .edgeEffect(EdgeEffect.Spring)
        .divider({
          strokeWidth: 0.5,
          color: '#EEEEEE',
          startMargin: 16,
          endMargin: 16
        })

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .title(this.title)
  }
}