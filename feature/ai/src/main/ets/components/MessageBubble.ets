import { Markdown } from '@luvi/lv-markdown-in';

interface BorderRadiusStyle {
  topLeft?: number;
  topRight?: number;
  bottomLeft?: number;
  bottomRight?: number;
  isAssistant?: boolean;
}

@Component
export struct MessageBubble {
  @Prop content: string = '';
  @Prop isUser: boolean = false;
  @Prop time: string = '';
  @Prop statusDesc: string = '';
  @Prop isAssistant: boolean = false;
  @Prop userAvatar: Resource = $r('app.media.avatar_img'); // 用户头像
  @Prop aiAvatar: Resource = $r('app.media.robot'); // AI头像

  build() {
    Row() {
      if (!this.isUser) {
        // AI头像：左侧
        this.buildAvatar(this.aiAvatar, false)
      }

      Column({ space: 4 }) {
        if (!this.isUser) {
          // AI名称和状态
          this.buildAssistantHeader()
        }

        // 消息气泡
        Column() {
          if (this.isAssistant) {
            // AI消息：Markdown流式渲染
            Markdown({
              text: this.content, // 内容属性（组件入参）
            })
              .padding({
                left: 12,
                right: 12,
                top: 10,
                bottom: 10
              })
              .width('100%');
          } else {
            Text(this.content)
              .fontSize(16)
              .fontColor(this.isUser ? '#FFFFFF' : '#1F2329')
              .padding({
                left: 12,
                right: 12,
                top: 10,
                bottom: 10
              })
          }
        }
        .backgroundColor(this.isUser ? '#337EFF' : '#FFFFFF')
        .borderRadius(this.getBorderRadius())
        .border({ width: this.isUser ? 0 : 1, color: '#E5E6EB' })
        .width('85%')

        // 时间
        if (this.time) {
          Text(this.time)
            .fontSize(12)
            .fontColor('#8F959E')
            .margin({ top: 4 })
            .alignSelf(this.isUser ? ItemAlign.End : ItemAlign.Start)
        }
      }
      .layoutWeight(1)
      .margin({
        left: this.isUser ? 0 : 8,
        right: this.isUser ? 8 : 0
      })

      if (this.isUser) {
        // 用户头像：右侧
        this.buildAvatar(this.userAvatar, true)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildAvatar(avatar: Resource, isRightSide: boolean) {
    Column() {
      Image(avatar)
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor('#E8F3FF')
    }
    .margin({
      left: isRightSide ? 8 : 0,
      right: isRightSide ? 0 : 8,
      top: !this.isUser ? 24 : 0 // AI头像下移以对齐内容（AI名称下方）
    })
  }

  @Builder
  buildAssistantHeader() {
    Row() {
      Text('AI助手')
        .fontSize(12)
        .fontColor('#666666')

      if (this.statusDesc && this.statusDesc !== '成功') {
        Text(`(${this.statusDesc})`)
          .fontSize(12)
          .fontColor('#FF4D4F')
          .margin({ left: 4 })
      }
    }
    .margin({ bottom: 4 })
  }

  private getBorderRadius(): BorderRadiusStyle {
    if (this.isUser) {
      return {
        topLeft: 16,
        topRight: 4,
        bottomLeft: 16,
        bottomRight: 16
      };
    } else {
      return {
        topLeft: 4,
        topRight: 16,
        bottomLeft: 16,
        bottomRight: 16
      };
    }
  }
}