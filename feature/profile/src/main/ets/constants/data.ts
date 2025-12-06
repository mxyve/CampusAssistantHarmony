import { UserInfo, SettingItem } from '../types/Types';

/**
 * 默认用户信息
 */
export const DEFAULT_USER_INFO: UserInfo = {
  id: 1,
  name: '李明',
  studentId: '2023521001',
  college: '计算机学院',
  role: '学生',
  avatar: 'app.media.ic_default_avatar'
};

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