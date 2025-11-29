export interface TabListItem {
  label: string;
  icon: Resource;
  selectedIcon: Resource;
  component: WrappedBuilder<[]>;
}