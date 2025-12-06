import { TabListItem } from '../types/Types';
import { MainPageVM } from '../viewModels/MainPageVM'
import { RouterMap, RouterModule } from "basic"
import { LayoutFull } from '@hmos/ui-base'

@Builder
export function MainPageBuilder() {
  MainPage()
}

@Entry
@Component
struct MainPage {
  navStack: NavPathStack = RouterModule.getStack();
  vm: MainPageVM = MainPageVM.instance
  private controller: TabsController = new TabsController();
  callBackFunc: () => void = () => {
    this.controller.changeIndex(1);
  };

  build() {
    Navigation(this.navStack) {
      LayoutFull({
        customBgColor: '#FFFFFF',
        buildContent: this.buildTabContent.bind(this)  // 绑定 this
      })
    }
    .hideTitleBar(true)
  }

  @Builder
  buildTabContent() {
    // 直接使用 this.vm，ArkTS会处理 this 指向
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.vm.curIndex, controller: this.controller }) {
        ForEach(this.vm.tabList, (item: TabListItem, index: number) => {
          TabContent() {
            item.component.builder();
          }
          .tabBar(this.tabBarBuilder(item, index))
        }, (item: TabListItem) => item.label);
      }
      .scrollable(false)
      .animationDuration(0)
      .barMode(BarMode.Fixed)
      .height('100%')
      .onChange((index: number) => {
        this.vm.curIndex = index;
      });
    }
    .height('100%')
    .width('100%')
  }

  @Builder
  tabBarBuilder(item: TabListItem, index: number) {
    // 这里可以直接访问 this.vm
    Column() {
      Image(this.vm.curIndex === index ? item.selectedIcon : item.icon)
        .width(24)
        .height(24)
      Text(item.label)
        .fontColor(this.vm.curIndex === index ? "#3F6AF6" : "#99000000")
        .fontSize(10)
        .margin({ top: 4 });
    }
    .width('100%')
    .padding({ top: 10 })
  }
}