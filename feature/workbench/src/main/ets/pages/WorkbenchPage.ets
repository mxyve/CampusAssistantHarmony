import { RouterModule, RouterMap } from 'basic';

// 服务图标数据类型定义（仅保留核心字段）
interface ServiceItem {
  id: number;
  name: string;
  icon: Resource;
  path: string;
}

@Builder
export function WorkbenchPageBuilder() {
  WorkbenchPage()
}

@Component
@Entry
struct WorkbenchPage {
  // 服务图标网格数据
  private serviceItems: ServiceItem[] = [
    {
      id: 1,
      name: '奖助助手',
      icon: $r('app.media.ic_school_scholarship'),
      path: RouterMap.SCHOLARSHIP_PAGE
    },
    {
      id: 2,
      name: '食堂',
      icon: $r('app.media.ic_school_cafeteria'),
      path: RouterMap.CANTEEN_PAGE
    },
    {
      id: 3,
      name: '图书馆',
      icon: $r('app.media.ic_school_library'),
      path: RouterMap.LIBRARY_PAGE
    },
    {
      id: 4,
      name: '体育馆',
      icon: $r('app.media.ic_school_gymnasium'),
      path: RouterMap.GYM_PAGE
    },
    {
      id: 5,
      name: '教学楼',
      icon: $r('app.media.ic_school_teaching_building'),
      path: RouterMap.TEACHING_BUILDING_PAGE
    },
    {
      id: 6,
      name: '校园卡',
      icon: $r('app.media.ic_school_campus_card_recharge'),
      path: RouterMap.CAMPUS_CARD_PAGE
    },
    {
      id: 7,
      name: '电费充值',
      icon: $r('app.media.ic_school_electricity_fee_reset'),
      path: RouterMap.ELECTRICITY_BILL_RECHARGE_PAGE
    },
    {
      id: 8,
      name: '医务室',
      icon: $r('app.media.ic_school_infirmary'),
      path: RouterMap.CLINIC_PAGE
    },
    {
      id: 9,
      name: '失物招领',
      icon: $r('app.media.ic_school_lost_add_office'),
      path: RouterMap.LOST_AND_FOUND_PAGE
    }
  ];

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          // 页面标题
          Text('校园服务')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16, bottom: 20, left: 16 })

          // 服务图标网格 - 3×3布局
          Column() {
            ForEach(
              this.serviceItems.filter((_, index: number) => index % 3 === 0),
              (item: ServiceItem, rowIndex: number) => {
                Row() {
                  ForEach(
                    this.serviceItems.slice(rowIndex * 3, rowIndex * 3 + 3),
                    (subItem: ServiceItem) => {
                      Column() {
                        Image(subItem.icon)
                          .width(68)
                          .height(68)
                          .objectFit(ImageFit.Contain)
                          .backgroundColor('#F5F5F5')
                          .borderRadius(10)
                          .padding(10)
                          .onClick(() => {
                            // 仅保留跳转逻辑
                            RouterModule.push(subItem.path);
                          })

                        Text(subItem.name)
                          .fontSize(12)
                          .margin({ top: 6 })
                      }
                      .width('33.33%')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                    },
                    (subItem: ServiceItem) => subItem.id.toString()
                  )
                }
                .width('100%')
                .padding({ bottom: 16 })
              },
              (item: ServiceItem, index: number) => index.toString()
            )
          }
          .margin({ bottom: 24, left: 12, right: 12 })

        }
        .width('100%')
        .backgroundColor('#F9F9F9')
      }
    }.hideTitleBar(true);
  }
}