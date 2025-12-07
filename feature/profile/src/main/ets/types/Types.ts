/**
 * 用户信息类型
 */
export interface UserInfo {
  id: number;
  username: string;
  nickname?: string;
  email?: string;
  mobile?: string | null;
  avatar?: string | null;
}

/**
 * 设置项类型
 */
export interface SettingItem {
  id: number;
  icon: string;
  title: string;
  subtitle?: string;
  type: 'navigation' | 'toggle' | 'logout';
  route?: string;
  value?: boolean;
}

/**
 * 个人中心页面数据
 */
export interface ProfilePageData {
  userInfo: UserInfo;
  settingItems: SettingItem[];
}
