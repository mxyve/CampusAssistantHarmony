@Builder
export function McpPageBuilder() {
  McpPage()
}

@Component
@Entry
struct McpPage {
  build() {
    NavDestination() {

    }.hideTitleBar(true);
  }
}
