import 'package:flutter/material.dart'; 
import '../../data/services/auth_service.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget { 
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess}); 
 
  @override 
  State<LoginPage> createState() => _LoginPageState(); 
} 
 
class _LoginPageState extends State<LoginPage> { 
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController(); 
  final passwordController = TextEditingController(); 
  final AuthService _authService = AuthService();
  bool _isObscure = true; 
  bool _isLoading = false;
 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      body: Container( 
        decoration: BoxDecoration( 
          gradient: LinearGradient( 
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight, 
            colors: [Colors.blue.shade900, Colors.teal.shade400], 
          ), 
        ), 
        child: Center( 
          child: SingleChildScrollView( 
            child: TweenAnimationBuilder( 
              duration: const Duration(milliseconds: 800), 
              tween: Tween<double>(begin: 0, end: 1), 
              builder: (context, double value, child) { 
                return Opacity( 
                  opacity: value, 
                  child: Transform.translate( 
                    offset: Offset(0, 50 * (1 - value)), 
                    child: child, 
                  ), 
                ); 
              }, 
              child: Container(
                width: 350, 
                padding: const EdgeInsets.all(30), 
                decoration: BoxDecoration( 
                  color: Colors.white.withOpacity(0.9), 
                  borderRadius: BorderRadius.circular(25), 
                  boxShadow: [ 
                    BoxShadow( 
                      color: Colors.black.withOpacity(0.2), 
                      blurRadius: 20, 
                      spreadRadius: 5, 
                    ), 
                  ], 
                ), 
                child: Form(
                  key: _formKey,
                  child: Column( 
                    mainAxisSize: MainAxisSize.min, 
                    children: [ 
                      Container( 
                        padding: const EdgeInsets.all(15), 
                        decoration: BoxDecoration( 
                          color: Colors.orange.shade50, 
                          shape: BoxShape.circle, 
                        ), 
                        child: Icon( 
                          Icons.local_pizza_rounded, 
                          size: 50, 
                          color: Colors.orange.shade800, 
                        ), 
                      ), 
                      const SizedBox(height: 20), 
                      const Text( 
                        "FoodGo Admin Portal", 
                        style: TextStyle( 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.5, 
                          color: Colors.black87, 
                        ), 
                      ), 
                      const SizedBox(height: 10), 
                      const Text( 
                        "Đăng nhập vào hệ thống quản trị", 
                        style: TextStyle(color: Colors.grey), 
                      ), 
                      const SizedBox(height: 30), 
   
                      TextFormField( 
                        controller: emailController, 
                        decoration: InputDecoration( prefixIcon: const Icon(Icons.email_outlined), 
                          labelText: "Email", 
                          filled: true, 
                          fillColor: Colors.grey.shade100, 
                          border: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(15), 
                            borderSide: BorderSide.none, 
                          ), 
                        ), 
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                          if (!value.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                      ), 
                      const SizedBox(height: 20), 
   
                      TextFormField( 
                        controller: passwordController, 
                        obscureText: _isObscure, 
                        decoration: InputDecoration( 
                          prefixIcon: const Icon(Icons.lock_outline), 
                          suffixIcon: IconButton( 
                            icon: Icon( 
                              _isObscure 
                                  ? Icons.visibility 
                                  : Icons.visibility_off, 
                            ), 
                            onPressed: () => 
                                setState(() => _isObscure = !_isObscure), 
                          ), 
                          labelText: "Password", 
                          filled: true, 
                          fillColor: Colors.grey.shade100, 
                          border: OutlineInputBorder( 
                            borderRadius: BorderRadius.circular(15), 
                            borderSide: BorderSide.none, 
                          ), 
                        ), 
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                      ), 
                      const SizedBox(height: 30), 
   
                      SizedBox( 
                        width: double.infinity, 
                        height: 55, 
                        child: ElevatedButton( 
                          onPressed: _isLoading ? null : () async { 
                            if (!_formKey.currentState!.validate()) return;
  
                            setState(() => _isLoading = true);
                            try {
                              await _authService.login(emailController.text.trim(), passwordController.text);
                              if (mounted) widget.onLoginSuccess();
                            } catch (e) {
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red, size: 28),
                                        SizedBox(width: 10),
                                        Text('Lỗi đăng nhập'),
                                      ],
                                    ),
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context), 
                                        child: const Text('ĐÓNG', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          }, 
                          style: ElevatedButton.styleFrom( 
                            backgroundColor: Colors.orange.shade800, 
                            foregroundColor: Colors.white, 
                            shape: RoundedRectangleBorder( 
                              borderRadius: BorderRadius.circular(15), 
                            ), 
                            elevation: 5, 
                          ), 
                          child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("ĐĂNG NHẬP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                        ), 
                      ), 
                      const SizedBox(height: 16), 
                      TextButton( 
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
                        }, 
                        child: const Text("Quên mật khẩu?"), 
                      ), 
                    ], 
                  ),
                ), 
              ), 
            ), 
          ), 
        ), 
      ), 
    ); 
  } 
}