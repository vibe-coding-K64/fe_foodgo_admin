import 'package:flutter/material.dart'; 
import 'sidebar.dart'; 
import 'admin_appbar.dart'; 

// Import all main pages to keep them in IndexedStack
import '../dashboard/dashboard_page.dart';
import '../orders/orders_page.dart';
import '../vouchers/vouchers_page.dart';
import '../finance/transaction_page.dart';
import '../finance/withdrawal_page.dart';
import '../reviews/reviews_page.dart';
import '../report_tickets/report_tickets_page.dart';
import '../profile/profile_page.dart';
import '../settings/system_config_page.dart';
import '../categorys/category_page.dart';
import '../banners/banners_page.dart';
import '../users/users_page.dart';
import '../store/stores_admin_page.dart';
import '../drivers/drivers_page.dart';
import '../notifications/notifications_page.dart';

class AdminLayout extends StatefulWidget { 
  final Widget child; 
  final Function(String) onNavigate; 
  final String currentRoute; 
  const AdminLayout({ 
    super.key, 
    required this.child, 
    required this.onNavigate, 
    required this.currentRoute, 
  }); 
  @override 
  State<AdminLayout> createState() => _AdminLayoutState(); 
} 

class _AdminLayoutState extends State<AdminLayout> { 
  late final List<String> _mainRoutes;
  late final List<bool> _pageActivated;

  @override
  void initState() {
    super.initState();
    
    _mainRoutes = [
      '/dashboard',
      '/users',
      '/stores',
      '/drivers',
      '/settings',
      '/menu-categories',
      '/banners',
      '/notifications',
      '/orders',
      '/vouchers',
      '/reviews',
      '/finance/transactions',
      '/finance/withdrawal',
      '/report-tickets',
      '/profile',
    ];

    final initialIndex = _mainRoutes.indexOf(widget.currentRoute);
    _pageActivated = List.generate(
      _mainRoutes.length,
      (index) => index == initialIndex || (initialIndex == -1 && index == 0),
    );
  }

  @override
  void didUpdateWidget(AdminLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int mainRouteIndex = _mainRoutes.indexOf(widget.currentRoute);
    if (mainRouteIndex != -1 && !_pageActivated[mainRouteIndex]) {
      _pageActivated[mainRouteIndex] = true;
    }
  }

  Widget _buildPageByIndex(int index) {
    switch (index) {
      case 0:
        return MyDashboard(onNavigate: widget.onNavigate);
      case 1:
        return UsersPage(onNavigate: widget.onNavigate);
      case 2:
        return StoresAdminPage(onNavigate: widget.onNavigate);
      case 3:
        return const DriversPage();
      case 4:
        return const SystemConfigPage();
      case 5:
        return MenuCategoryPage(onNavigate: widget.onNavigate);
      case 6:
        return BannersPage(onNavigate: widget.onNavigate);
      case 7:
        return NotificationsPage(onNavigate: widget.onNavigate);
      case 8:
        return OrdersPage(onNavigate: widget.onNavigate);
      case 9:
        return VouchersPage(onNavigate: widget.onNavigate);
      case 10:
        return const ReviewsPage();
      case 11:
        return const TransactionPage();
      case 12:
        return const WithdrawalPage();
      case 13:
        return const ReportTicketsPage();
      case 14:
        return ProfilePage(onNavigate: widget.onNavigate);
      default:
        return const SizedBox.shrink();
    }
  }

  @override 
  Widget build(BuildContext context) { 
    final int mainRouteIndex = _mainRoutes.indexOf(widget.currentRoute);
    final Widget displayWidget;

    if (mainRouteIndex != -1) {
      // Main page in sidebar -> display from IndexedStack (keeps state alive lazily)
      displayWidget = IndexedStack(
        index: mainRouteIndex,
        children: List.generate(_mainRoutes.length, (index) {
          if (_pageActivated[index]) {
            return _buildPageByIndex(index);
          } else {
            return const SizedBox.shrink();
          }
        }),
      );
    } else {
      // Dynamic page (e.g. details / sub-form) -> display dynamic child
      displayWidget = widget.child;
    }

    return Scaffold( 
      body: Row( 
        children: [ 
          Sidebar(
            onNavigate: widget.onNavigate, 
            currentRoute: widget.currentRoute, 
          ), 
          Expanded( 
            child: Column(
              children: [
                SizedBox(
                  height: 57,
                  child: AdminAppBar(onNavigate: widget.onNavigate),
                ),
                Expanded(
                  child: Container( 
                    color: Colors.grey[100], 
                    padding: const EdgeInsets.all(24), 
                    child: displayWidget, 
                  ), 
                ),
              ],
            ), 
          ), 
        ], 
      ), 
    ); 
  } 
} 