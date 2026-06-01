import 'package:flutter/material.dart'; 
import '../../data/services/auth_service.dart';
 
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget 
{ 
  const AdminAppBar({super.key}); 
 
  @override 
  Widget build(BuildContext context) { 

 
    return AppBar( 
      backgroundColor: Colors.white, 
      elevation: 0, // Bỏ bóng đổ mặc định 
      automaticallyImplyLeading: false, 
      titleSpacing: 24, 
      // Thêm một đường kẻ mảnh ở dưới AppBar 
      bottom: PreferredSize( preferredSize: const Size.fromHeight(1.0), 
        child: Container(color: Colors.grey.withOpacity(0.2), height: 1.0), 
      ), 
      title: Row( 
        children: [ 
          /// SEARCH BAR - Làm bo tròn và chuyên nghiệp hơn 
          Expanded( 
            flex: 2, 
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Container( 
                height: 42, 
                decoration: BoxDecoration( 
                  color: Colors.grey[50], 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.grey[200]!), 
                ), 
                child: TextField( 
                  decoration: InputDecoration( 
                    hintText: "Tìm kiếm hệ thống...", 
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), 
                    prefixIcon: Icon( 
                      Icons.search, 
                      color: Colors.grey[400], 
                      size: 20, 
                    ), 
                    border: InputBorder.none, 
                    contentPadding: const EdgeInsets.symmetric(vertical: 10), 
                  ), 
                ), 
              ), 
            ),
          ), 
 
          const Spacer(flex: 1), // Tạo khoảng trống giữa search và icons 
          ///ACTIONS GROUP 
          _buildActionButton(Icons.language, "Ngôn ngữ", () {}), 
          _buildActionButton( 
            Icons.notifications_none_outlined, 
            "Thông báo", 
            () {}, 
          ), 
          _buildActionButton(Icons.shopping_cart_outlined, "Đơn hàng", () {}), 
          _buildActionButton(Icons.settings_outlined, "Cài đặt", () {}), 
 
          const VerticalDivider(indent: 15, endIndent: 15, width: 40), 
 
          /// USER INFO SECTION
          PopupMenuButton<String>( 
            offset: const Offset(0, 55), 
            shape: RoundedRectangleBorder( 
              borderRadius: BorderRadius.circular(12), 
            ), 
            child: MouseRegion( 
              cursor: SystemMouseCursors.click, 
              child: Row( 
                children: [ 
                  Column( 
                    crossAxisAlignment: CrossAxisAlignment.end, 
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: const [ 
                     
                      Text( 
                        "Quản trị viên", 
                        style: TextStyle( 
                          fontSize: 11, 
                          color: Color(0xFFFF6B35), 
                        ), 
                      ), 
                    ], 
                  ), 
                  const SizedBox(width: 12), 
                  Container( 
                    decoration: BoxDecoration( 
                      shape: BoxShape.circle, 
                      border: Border.all( 
                        color: const Color(0xFFFF6B35).withOpacity(0.2), 
                        width: 2, 
                      ), 
                    ), 
                    child: const CircleAvatar( 
                      radius: 18, 
                      backgroundColor: Color(0xFFFF6B35), 
                      child: Text( 
                        "UA", 
                        style: TextStyle(color: Colors.white, fontSize: 12), 
                      ), 
                    ), 
                  ), 
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ], 
              ), 
            ), 
            itemBuilder: (context) => [ 
              _buildPopupItem( 
                "profile", 
                Icons.person_outline, 
                "Thông tin cá nhân", 
              ), 
              _buildPopupItem("settings", Icons.security, "Bảo mật"), 
              const PopupMenuDivider(), 
              _buildPopupItem( 
                "logout", 
                Icons.logout, 
                "Đăng xuất", 
                color: Colors.red, 
              ), 
            ], 
            onSelected: (value) async { 
              if (value == "logout") { 
                await AuthService().logout();
              } 
            }, 
          ), 
        ], 
      ), 
    ); 
  } 
 
  /// Widget bổ trợ tạo Icon Button đẹp hơn 
  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) { 
    return Padding( 
      padding: const EdgeInsets.symmetric(horizontal: 4), 
      child: Tooltip( 
        message: tooltip, 
        child: IconButton( 
          onPressed: onTap, 
          icon: Icon(icon, color: Colors.black54, size: 22), 
          hoverColor: Colors.blue.withOpacity(0.05), 
          splashRadius: 22, 
        ), 
      ), 
    ); 
  } 
 
  /// Widget bổ trợ tạo Item Menu đẹp hơn 
  PopupMenuItem<String> _buildPopupItem( 
    String value, 
    IconData icon,
      String title, { 
    Color? color, 
  }) { 
    return PopupMenuItem( 
      value: value, 
      child: Row( 
        children: [ 
          Icon(icon, size: 18, color: color ?? Colors.black54), 
          const SizedBox(width: 12), 
          Text(title, style: TextStyle(color: color, fontSize: 14)), 
        ], 
      ), 
    ); 
  } 
 
  @override 
  Size get preferredSize => const Size.fromHeight(65); // Tăng chiều cao lên một chút cho thoáng 
} 