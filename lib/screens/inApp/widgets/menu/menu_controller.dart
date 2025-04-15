class MenuController {
  static final MenuController instance = MenuController._internal();

  MenuController._internal();
  Type? sourceScreen;

  void selectSource(Type screenType) { sourceScreen = screenType; }
  void clearSource() { sourceScreen = null; }
}