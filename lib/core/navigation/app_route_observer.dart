import 'package:flutter/material.dart';

import '../audio/app_audio_service.dart';

class AppAudioRouteObserver extends NavigatorObserver {
  void _selectMusic(Route<dynamic>? route) {
    final routeName = route?.settings.name;
    if (routeName == null || routeName.isEmpty) return;
    AppAudioService.instance.setCurrentRoute(routeName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _selectMusic(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _selectMusic(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _selectMusic(newRoute);
  }
}

final AppAudioRouteObserver appRouteObserver = AppAudioRouteObserver();
