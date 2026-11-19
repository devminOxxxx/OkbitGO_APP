import 'package:flutter/material.dart';
import '../utils/enums.dart';

class NavigationProvider extends ChangeNotifier {
  NavigationTab _currentTab = NavigationTab.home;

  NavigationTab get currentTab => _currentTab;
  int get currentIndex => _currentTab.tabIndex;

  void setTab(NavigationTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      notifyListeners();
    }
  }

  void setIndex(int index) {
    final tab = NavigationTab.fromIndex(index);
    setTab(tab);
  }

  void goToTab(BuildContext context, NavigationTab tab,
      {int? initialTabIndex}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
    setTab(tab);

    // initialTabIndex가 제공되면 해당 탭의 초기 인덱스를 설정하는 로직
    if (initialTabIndex != null && tab == NavigationTab.schoolLife) {
      // 학교생활 탭의 내부 탭 인덱스를 설정하는 로직
      // 이 정보를 저장하여 학교생활 화면에서 활용할 수 있도록 함
      _schoolLifeInitialTabIndex = initialTabIndex;
      notifyListeners();
    }
  }

  // 학교생활 탭의 초기 인덱스를 저장하는 변수
  int _schoolLifeInitialTabIndex = 0;

  // 학교생활 탭의 초기 인덱스를 가져오는 getter
  int get schoolLifeInitialTabIndex => _schoolLifeInitialTabIndex;

  // 학교생활 탭의 초기 인덱스를 재설정하는 메서드
  void resetSchoolLifeInitialTabIndex() {
    _schoolLifeInitialTabIndex = 0;
  }
}
