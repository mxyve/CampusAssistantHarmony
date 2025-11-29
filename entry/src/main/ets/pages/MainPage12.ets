import { HomePage } from './HomePage12';
import { LightThemePage } from './workbench/LightThemePage'

@Entry
@Component
export struct MainPage {
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pageInfos) {
      HomePage() // 首页（内部再嵌 Tabs）
    }
    .width('100%')
    .height('100%')
    .mode(NavigationMode.Stack)
    .navDestination(this.pageMap)
    .hideTitleBar(true)
    .backgroundColor('#F5F5F5')
  }

  @Builder
  pageMap(name: string) {
    if (name === 'LightThemePage') {
      LightThemePage();
    }
  }
}