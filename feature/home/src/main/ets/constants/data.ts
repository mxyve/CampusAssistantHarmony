import {
  QuickFunction, CampusNotification, CampusNews, NotificationType
} from '../types/Types';

/**
 * 快捷功能数据
 */
export const QUICK_FUNCTIONS: QuickFunction[] = [
  {
    id: 1,
    icon: 'app.media.ic_course_exam_activity',
    title: '课程表',
    pageUrl: 'pages/SchedulePage',
    description: '查看课程安排'
  },
  {
    id: 2,
    icon: 'app.media.ic_course_score',
    title: '成绩查询',
    pageUrl: 'pages/GradePage',
    description: '查询考试成绩'
  },
  {
    id: 3,
    icon: 'app.media.ic_school_campus_card_recharge',
    title: '校园卡',
    pageUrl: 'pages/CampusCardPage',
    description: '校园卡服务'
  },
  {
    id: 4,
    icon: 'app.media.ic_school_library',
    title: '图书馆',
    pageUrl: 'pages/LibraryPage',
    description: '图书借阅查询'
  }
];

/**
 * 校园通知数据
 */
export const CAMPUS_NOTIFICATIONS: CampusNotification[] = [
  {
    id: 1,
    type: NotificationType.EXAM,
    title: '期末考试时间调整通知',
    time: '2025-12-04 09:30',
    content: '国家奖英语课堂，部分课程期末考试时间变更',
    unread: true,
    source: '教务处',
    priority: 1
  },
  {
    id: 2,
    type: NotificationType.RECRUITMENT,
    title: '校园招聘会安排',
    time: '2025-12-03 14:20',
    content: '2026届毕业生校园招聘会将于12月10日在体育馆举行',
    unread: false,
    source: '就业指导中心',
    priority: 2
  }
];

/**
 * 校园动态数据
 */
export const CAMPUS_NEWS: CampusNews[] = [
  {
    id: 1,
    title: '科技文化节圆满落幕',
    content: '第五届校园科技文化节吸引了全校师生踊跃参与。',
    image: 'app.media.school_huodong',
    date: '2025-12-02',
    author: '宣传部',
    tags: ['文化活动', '科技节'],
    views: 1250
  }
];

/**
 * 默认首页数据
 */
export const DEFAULT_HOME_DATA = {
  quickFunctions: QUICK_FUNCTIONS,
  notifications: CAMPUS_NOTIFICATIONS,
  campusNews: CAMPUS_NEWS
};