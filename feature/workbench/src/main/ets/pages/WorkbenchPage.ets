import { RouterModule, RouterMap } from 'basic';
import { SessionApi, CreateSessionParams } from '../api/SessionApi'; // 路径根据你的项目调整
import promptAction from '@ohos.promptAction';
import { storageUtil } from 'storage'; // 若需要获取用户信息/登录状态，按需导入

// 服务图标数据类型定义（仅保留核心字段）
interface ServiceItem {
  id: number;
  name: string;
  icon: Resource;
  path: string;
}

export interface ChatPageJumpParams {
  sessionId: number;
}

interface UserInfo {
  id?: number;
  username?: string;
  nickname?: string;
  avatar?: string;
  email?: string;
  mobile?: string;
}

@Builder
export function WorkbenchPageBuilder() {
  WorkbenchPage()
}

@Component
@Entry
struct WorkbenchPage {
  // 服务图标网格数据
  private serviceItems: ServiceItem[] = [
    {
      id: 1,
      name: '奖助助手',
      icon: $r('app.media.ic_school_scholarship'),
      path: RouterMap.SCHOLARSHIP_PAGE
    },
    {
      id: 2,
      name: '校园助手',
      icon: $r('app.media.ic_campus_assistant'),
      path: RouterMap.CAMPUS_ASSISTANT_AGENT_PAGE
    },
    {
      id: 3,
      name: '图书馆',
      icon: $r('app.media.ic_school_library'),
      path: RouterMap.LIBRARY_PAGE
    },
    {
      id: 4,
      name: '体育馆',
      icon: $r('app.media.ic_school_gymnasium'),
      path: RouterMap.GYM_PAGE
    },
    {
      id: 5,
      name: '教学楼',
      icon: $r('app.media.ic_school_teaching_building'),
      path: RouterMap.TEACHING_BUILDING_PAGE
    },
    {
      id: 6,
      name: '校园卡',
      icon: $r('app.media.ic_school_campus_card_recharge'),
      path: RouterMap.CAMPUS_CARD_PAGE
    },
    {
      id: 7,
      name: '电费充值',
      icon: $r('app.media.ic_school_electricity_fee_reset'),
      path: RouterMap.ELECTRICITY_BILL_RECHARGE_PAGE
    },
    {
      id: 8,
      name: '医务室',
      icon: $r('app.media.ic_school_infirmary'),
      path: RouterMap.CLINIC_PAGE
    },
    {
      id: 9,
      name: '失物招领',
      icon: $r('app.media.ic_school_lost_add_office'),
      path: RouterMap.LOST_AND_FOUND_PAGE
    }
  ];
  @StorageLink('isLoggedIn') isLoggedIn: boolean = false; // 同步全局登录状态（布尔类型，无需异步获取）
  @StorageLink('currentUserInfo') currentUserInfo: UserInfo | null = null; // 同步全局用户信息

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          // 页面标题
          Text('校园服务')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 16, bottom: 20, left: 16 })

          // 服务图标网格 - 3×3布局
          Column() {
            ForEach(
              this.serviceItems.filter((_, index: number) => index % 3 === 0),
              (item: ServiceItem, rowIndex: number) => {
                Row() {
                  ForEach(
                    this.serviceItems.slice(rowIndex * 3, rowIndex * 3 + 3),
                    (subItem: ServiceItem) => {
                      Column() {
                        Image(subItem.icon)
                          .width(68)
                          .height(68)
                          .objectFit(ImageFit.Contain)
                          .backgroundColor('#F5F5F5')
                          .borderRadius(10)
                          .padding(10)
                          .onClick(() => {
                            if (subItem.name === '校园助手') {
                              // 校园助手：调用创建会话并跳转的方法
                              this.handleCampusAssistantClick();
                            } else {
                              // 其他服务：保持原有直接跳转逻辑
                              RouterModule.push(subItem.path);
                            }
                          })

                        Text(subItem.name)
                          .fontSize(12)
                          .margin({ top: 6 })
                      }
                      .width('33.33%')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                    },
                    (subItem: ServiceItem) => subItem.id.toString()
                  )
                }
                .width('100%')
                .padding({ bottom: 16 })
              },
              (item: ServiceItem, index: number) => index.toString()
            )
          }
          .margin({ bottom: 24, left: 12, right: 12 })

        }
        .width('100%')
        .backgroundColor('#F9F9F9')
      }
    }.hideTitleBar(true);
  }

  private async handleCampusAssistantClick() {
    // 1. 登录状态校验（参考 AiPage，直接使用 @StorageLink 绑定的 isLoggedIn，无需异步）
    if (!this.isLoggedIn) { // 直接判断布尔类型，无类型转换问题
      promptAction.showToast({ message: '请先登录后使用校园助手' });
      return;
    }

    // 可选：如需用户ID（如创建会话需要关联用户），参考 AiPage 获取
    const userId = this.currentUserInfo?.id;
    if (!userId) {
      promptAction.showToast({ message: '用户信息不完整，请重新登录' });
      return;
    }

    // 2. 构建创建会话参数，指定agentType为edu_agent（原有逻辑不变）
    const createParams: CreateSessionParams = {
      title: '校园助手会话',
      modelName: 'qwen-turbo',
      agentType: 'edu_agent'
    };

    try {
      promptAction.showToast({ message: '正在初始化校园助手...' });
      // 3. 调用创建会话接口（原有逻辑不变）
      const sessionResult = await SessionApi.createSession(createParams);
      if (!sessionResult || !sessionResult.id) {
        promptAction.showToast({ message: '校园助手初始化失败' });
        return;
      }

      // 4. 会话创建成功，携带sessionId跳转到ChatPage（原有逻辑不变）
      RouterModule.push(RouterMap.CHAT_PAGE, {
        sessionId: sessionResult.id
      } as ChatPageJumpParams);
    } catch (error) {
      console.error('创建校园助手会话失败:', error);
      promptAction.showToast({ message: '校园助手初始化失败，请重试' });
    }
  }
}
