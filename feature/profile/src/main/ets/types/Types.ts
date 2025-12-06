/**
 * 用户信息类型
 */
export interface UserInfo {
  id: number;
  name: string;
  studentId: string;
  college: string;
  role: string;
  avatar?: string;
  email?: string;
  phone?: string;
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

/**
 * 编辑资料页面参数
 */
export interface EditProfileParams {
  userInfo: UserInfo;
}
