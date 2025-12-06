/**
 * 快捷功能类型定义
 */
export interface QuickFunction {
  id: number; // 功能ID
  icon: string; // 图标资源
  title: string; // 功能标题
  pageUrl: string; // 跳转页面URL
  description?: string; // 可选描述
}

/**
 * 通知类型枚举
 */
export enum NotificationType {
  NOTICE = 'notice', // 通知
  RECRUITMENT = 'recruitment', // 招聘
  EXAM = 'exam', // 考试
  ACTIVITY = 'activity', // 活动
  EMERGENCY = 'emergency' // 紧急
}

/**
 * 校园通知类型定义
 */
export interface CampusNotification {
  id: number; // 通知ID
  type: NotificationType; // 通知类型
  title: string; // 通知标题
  time: string; // 发布时间
  content: string; // 通知内容
  unread: boolean; // 是否未读
  source?: string; // 可选来源
  priority?: number; // 可选优先级
}

/**
 * 校园动态类型定义
 */
export interface CampusNews {
  id: number; // 动态ID
  title: string; // 动态标题
  content: string; // 动态内容
  image: string; // 图片资源
  date?: string; // 可选发布日期
  author?: string; // 可选发布者
  tags?: string[]; // 可选标签
  views?: number; // 可选浏览量
}

/**
 * 首页数据集合类型
 */
export interface HomePageData {
  quickFunctions: QuickFunction[];
  notifications: CampusNotification[];
  campusNews: CampusNews[];
}

/**
 * 页面路由参数类型
 */
export interface RouteParams {
  pageUrl: string;
  params?: Record<string, any>;
}