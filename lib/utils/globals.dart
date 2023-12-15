// globals.dart
library globals;

import 'package:flutter/material.dart';
import 'package:pronto/cart/cart_screen.dart';
import 'package:pronto/home/home_screen.dart';
import 'package:pronto/home/tab/tab.dart';
import 'package:pronto/plan/plan.dart';
import 'package:provider/provider.dart';

bool showAddress = false; // An example global variable

class CustomRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _updateTabBasedOnRoute(PageRoute<dynamic> route, BuildContext context) {
    final activeTabProvider =
        Provider.of<ActiveTabProvider>(context, listen: false);

    print("Route name: ${route.settings.name}"); // Add debug print

    if (route.settings.name == MyHomePage.routeName) {
      activeTabProvider.setActiveTabIndex(0);
    } else if (route.settings.name == MyPlan.routeName) {
      activeTabProvider.setActiveTabIndex(1);
    } else if (route.settings.name == MyCart.routeName) {
      activeTabProvider.setActiveTabIndex(2);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _updateTabBasedOnRoute(previousRoute, route.navigator!.context);
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _updateTabBasedOnRoute(route, route.navigator!.context);
    }
  }
}
