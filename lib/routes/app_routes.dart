import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/auth/login_page.dart';
import '../views/layout/admin_layout.dart';
import '../views/dashboard/dashboard_page.dart';

import '../views/orders/orders_page.dart';
import '../views/orders/order_detail_page.dart';
import '../views/vouchers/vouchers_page.dart';
import '../views/vouchers/voucher_add_edit_page.dart';
import '../views/finance/transaction_page.dart';
import '../views/finance/withdrawal_page.dart';
import '../views/reviews/reviews_page.dart';
import '../views/chat/chat_page.dart';
import '../views/notifications/notifications_page.dart';
import '../views/report_tickets/report_tickets_page.dart';
import '../views/profile/profile_page.dart';
import '../views/profile/settings_page.dart';
import '../views/settings/system_config_page.dart';
import '../views/categorys/category_page.dart';
import '../views/banners/banners_page.dart';
import '../views/users/users_page.dart';
import '../views/store/stores_admin_page.dart';
import '../views/drivers/drivers_page.dart';

class AppRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final GlobalKey<NavigatorState> navigatorKey;
  String _currentPath = "/dashboard";

  AppRouterDelegate()
      : navigatorKey = GlobalKey<NavigatorState>();

  @override
  String? get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_currentPath) {
      // 1. Hệ thống
      case "/dashboard":
        page = const MyDashboard();
        break;
      case "/stores":
        page = StoresAdminPage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/drivers":
        page = const DriversPage();
        break;
      case "/menu-categories":
        page = MenuCategoryPage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/banners":
        page = BannersPage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;

      // 3. Kinh doanh
      case "/orders":
        page = OrdersPage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/orders/detail":
        page = OrderDetailPage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/vouchers":
        page = VouchersPage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/vouchers/add":
        page = VoucherFormPage(
          isEdit: false,
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/vouchers/edit":
        page = VoucherFormPage(
          isEdit: true,
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/reviews":
        page = const ReviewsPage();
        break;

      // 4. Tài chính
      case "/finance/transactions":
        page = const TransactionPage();
        break;
      case "/finance/withdrawal":
        page = const WithdrawalPage();
        break;

      // 5. Hỗ trợ
      case "/chat":
        page = const ChatPage();
        break;
      case "/notifications":
        page = const NotificationsPage();
        break;
      case "/report-tickets":
        page = const ReportTicketsPage();
        break;

      // 6. Tài khoản
      case "/profile":
        page = ProfilePage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;
      case "/settings":
        page = const SystemConfigPage();
        break;
      case "/users":
        page = UsersPage(
          onNavigate: (path) {
            _currentPath = path;
            notifyListeners();
          },
        );
        break;

      default:
        page = const MyDashboard();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          return Navigator(
            key: navigatorKey,
            pages: [
              MaterialPage(
                child: LoginPage(
                  onLoginSuccess: () {
                    _currentPath = "/dashboard";
                    notifyListeners();
                  },
                ),
              ),
            ],
            onPopPage: (route, result) => route.didPop(result),
          );
        }

        return Navigator(
          key: navigatorKey,
          pages: [
            MaterialPage(
              child: AdminLayout(
                currentRoute: _currentPath,
                onNavigate: (path) {
                  _currentPath = path;
                  notifyListeners();
                },
                child: page,
              ),
            ),
          ],
          onPopPage: (route, result) => route.didPop(result),
        );
      },
    );
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    _currentPath = configuration;
  }
}

class AppRouteParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation.uri.path.isEmpty ? "/dashboard" : routeInformation.uri.path;
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) {
    return RouteInformation(uri: Uri.parse(configuration));
  }
}
