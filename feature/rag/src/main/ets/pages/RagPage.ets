@Builder
export function RagPageBuilder() {
  RagPage()
}

@Component
@Entry
struct RagPage {
  build() {
    NavDestination() {
      Text("RAG")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
    }.hideTitleBar(true);
  }
}
