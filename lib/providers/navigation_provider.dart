import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentTabIndex = 0;

  int get currentTabIndex => _currentTabIndex;

  /// Key for the HomeShell's Scaffold — used to open the nav drawer from
  /// any tab screen's AppTopBar without needing the drawer on every Scaffold.
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void setTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }
}
