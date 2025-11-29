@Builder
export function RagPageBuilder() {
  RagPage()
}

@Component
@Entry
struct RagPage {
  build() {
    NavDestination() {

    }.hideTitleBar(true);
  }
}
