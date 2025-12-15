import { TabListItem } from '../types/Types'
import { HomePageBuilder } from 'home'
import { AiPageBuilder } from 'ai'
import { WorkbenchPageBuilder } from 'workbench'
import { ProfilePageBuilder } from 'profile'

const TAG: string = 'MainPageVM';

@ObservedV2
export class MainPageVM {
  @Trace curIndex: number = 0;
  public tabList: TabListItem[] = [
    {
      label: '首页',
      icon: $r('app.media.nav_home_normal'),
      selectedIcon: $r('app.media.nav_home_selected'),
      component: wrapBuilder(HomePageBuilder),
    },
    {
      label: '对话',
      icon: $r('app.media.nav_chat_normal'),
      selectedIcon: $r('app.media.nav_chat_selected'),
      component: wrapBuilder(AiPageBuilder),
    },
    {
      label: '工作台',
      icon: $r('app.media.nav_workbench_normal'),
      selectedIcon: $r('app.media.nav_workbench_selected'),
      component: wrapBuilder(WorkbenchPageBuilder),
    },
    {
      label: '我的',
      icon: $r('app.media.nav_profile_normal'),
      selectedIcon: $r('app.media.nav_profile_selected'),
      component: wrapBuilder(ProfilePageBuilder),
    },
  ];
  private static _instance: MainPageVM;

  public static get instance() {
    if (!MainPageVM._instance) {
      MainPageVM._instance = new MainPageVM();
    }
    return MainPageVM._instance;
  }
}