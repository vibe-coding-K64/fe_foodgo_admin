import 'package:flutter/material.dart'; 
import 'sidebar.dart'; 
import 'admin_appbar.dart'; 
 
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
  @override 
  Widget build(BuildContext context) { 
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
                const SizedBox(
                  height: 57,
                  child: AdminAppBar(),
                ),
                Expanded(
                  child: Container( 
                    color: Colors.grey[100], 
                    padding: const EdgeInsets.all(24), 
                    child: widget.child, 
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