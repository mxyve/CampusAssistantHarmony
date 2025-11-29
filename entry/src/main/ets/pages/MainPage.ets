import { TabListItem } from "../types/Types"
import { MainPageVM } from "../viewModels/MainPageVM"

@Builder
export function MainPageBuilder() {
  MainPage()
}

@Entry
@Component
struct MainPage {
  vm: MainPageVM = MainPageVM.instance
  // 主动控制导航切换
  private controller: TabsController = new TabsController();
  callBackFunc: () => void = () => {
    this.controller.changeIndex(1)
  };

  build() {
    NavDestination() {
      Column() {
        // 鸿蒙原生底部导航组件
        Tabs({ barPosition: BarPosition.End, index: this.vm.curIndex, controller: this.controller }) {
          ForEach(this.vm.tabList, (item: TabListItem, index: number) => {
            TabContent() {
              item.component.builder();
            }
            // 设置导航项的底部图标 + 文字
            .tabBar(this.tabBarBuilder(item, index))
            .clip(index !== 0)
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
          }, (item: TabListItem) => item.label);
        }
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        // 禁止导航栏横向滚动
        .scrollable(false)
        .height('100%')
        // 关闭导航切换动画
        .animationDuration(0)
        // 导航栏固定模式
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.vm.curIndex = index;
        });
      }
      .backgroundColor(Color.White)
      // 适配系统安全区域
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
    }
    .hideTitleBar(true)
  }

  @Builder
  tabBarBuilder(item: TabListItem, index: number) {
    Column() {
      Image(this.vm.curIndex === index ? item.selectedIcon : item.icon)
        .width(24)
        .height(24)
      Text(item.label)
        .fontColor(this.vm.curIndex === index ? '#3F6AF6' : '#99000000')
        .fontSize(10)
        .margin({ top: 4 })
    }.width('100%').padding({ top: 10 })
  }
}