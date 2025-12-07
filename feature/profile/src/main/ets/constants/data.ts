import { UserInfo, SettingItem } from '../types/Types';

/**
 * 设置项列表
 */
export const SETTING_ITEMS: SettingItem[] = [
  {
    id: 1,
    icon: 'app.media.ic_settings_setting',
    title: '账号设置',
    type: 'navigation',
    route: 'AccountSettingsPage'
  },
  {
    id: 2,
    icon: 'app.media.ic_settings_notice',
    title: '通知设置',
    type: 'navigation',
    route: 'NotificationSettingsPage'
  },
  {
    id: 3,
    icon: 'app.media.ic_settings_theme',
    title: '通用设置',
    type: 'navigation',
    route: 'GeneralSettingsPage'
  },
  {
    id: 4,
    icon: 'app.media.ic_settings_about',
    title: '关于我们',
    type: 'navigation',
    route: 'AboutPage'
  }
];