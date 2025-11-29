@Builder
export function AiPageBuilder() {
  AiPage()
}

@Component
@Entry
struct AiPage {
  build() {
    NavDestination() {

    }.hideTitleBar(true);
  }
}
