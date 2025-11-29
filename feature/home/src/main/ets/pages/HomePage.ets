@Builder
export function HomePageBuilder() {
  HomePage()
}

@Component
@Entry
struct HomePage {
  build() {
    NavDestination() {

    }.hideTitleBar(true);
  }
}
