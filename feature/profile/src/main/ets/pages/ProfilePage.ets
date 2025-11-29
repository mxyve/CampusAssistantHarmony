@Builder
export function ProfilePageBuilder() {
  ProfilePage()
}

@Component
@Entry
struct ProfilePage {
  build() {
    NavDestination() {

    }.hideTitleBar(true);
  }
}
