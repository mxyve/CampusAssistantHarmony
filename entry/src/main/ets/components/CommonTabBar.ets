// components/CommonTabBar.ets
import { CommonTabItem, CommonTabBarStyle } from '../types/CommonTypes';

@Component
export struct CommonTabBar {
  /**
   * 必传参数：底部Tab列表配置
   */
  @Prop tabList: CommonTabItem[] = [];
  /**
   * 必传参数：当前选中索引（双向绑定，组件内切换同步父组件）
   */
  @Link curIndex: number;
  /**
   * 可选参数：Tab控制器（父组件需手动控制Tab切换时传入）
   */
  @Prop controller?: TabsController;
  /**
   * 可选参数：Tab样式配置（默认值与原代码保持一致）
   */
  @Prop tabStyle: CommonTabBarStyle = {
    tabBgColor: '#FFFFFF',
    iconSize: 24,
    textSize: 10,
    textSelectedColor: '#3F6AF6',
    textNormalColor: '#99000000',
    paddingTop: 10,
    isScrollable: false,
    animationDuration: 0
  };

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        index: this.curIndex,
        controller: this.controller || new TabsController()
      }) {
        ForEach(this.tabList, (item: CommonTabItem, index: number) => {
          TabContent() {
            item.component.builder(); // 渲染对应页面
          }
          .tabBar(this.buildTabItem(item, index))
        }, (item: CommonTabItem) => item.label); // 唯一标识
      }
      .scrollable(this.tabStyle.isScrollable || false)
      .animationDuration(this.tabStyle.animationDuration || 0)
      .barMode(BarMode.Fixed)
      .height('100%')
      .backgroundColor(this.tabStyle.tabBgColor || '#FFFFFF')
      .onChange((index: number) => {
        this.curIndex = index; // 切换时同步选中索引
      });
    }
    .height('100%')
    .width('100%');
  }

  /**
   * 内部封装TabBar样式（与原代码一致，支持样式配置覆盖）
   */
  @Builder
  buildTabItem(item: CommonTabItem, index: number) {
    Column() {
      Image(this.curIndex === index ? item.selectedIcon : item.icon)
        .width(this.tabStyle.iconSize || 24)
        .height(this.tabStyle.iconSize || 24)
      Text(item.label)
        .fontColor(this.curIndex === index ? (this.tabStyle.textSelectedColor || '#3F6AF6') :
          (this.tabStyle.textNormalColor || '#99000000'))
        .fontSize(this.tabStyle.textSize || 10)
        .margin({ top: 4 });
    }
    .width('100%')
    .padding({ top: this.tabStyle.paddingTop || 10 });
  }
}