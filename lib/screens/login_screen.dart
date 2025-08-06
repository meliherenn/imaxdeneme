import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imaxip/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _serverUrlController.text = 'http://erdemandroid.pro:80';
    _usernameController.text = 'MelihbJk';
    _passwordController.text = 'Mlh1903grsn34';
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _serverUrlController.text,
        _usernameController.text,
        _passwordController.text,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş Hatası: ${authProvider.errorMessage ?? "Bilinmeyen bir hata oluştu."}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Giriş Yap', style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9))),
                  SizedBox(height: 40.h),

                  // ODAKLANILABİLİR YAZI ALANI
                  FocusableField(
                    autofocus: true,
                    child: TextFormField(
                      controller: _serverUrlController,
                      decoration: InputDecoration(labelText: 'Sunucu Adresi (URL)', prefixIcon: Icon(Icons.http, color: Colors.grey[400])),
                      validator: (value) => value == null || value.isEmpty ? 'Lütfen sunucu adresini girin' : null,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // ODAKLANILABİLİR YAZI ALANI
                  FocusableField(
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: 'Kullanıcı Adı', prefixIcon: Icon(Icons.person, color: Colors.grey[400])),
                      validator: (value) => value == null || value.isEmpty ? 'Lütfen kullanıcı adını girin' : null,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // ODAKLANILABİLİR YAZI ALANI
                  FocusableField(
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock, color: Colors.grey[400])),
                      validator: (value) => value == null || value.isEmpty ? 'Lütfen şifrenizi girin' : null,
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // ODAKLANILABİLİR BUTON
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      if (auth.isLoading) {
                        return const CircularProgressIndicator(color: Colors.amber);
                      }
                      return FocusableField(
                        isButton: true,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: Text('Giriş Yap', style: TextStyle(fontSize: 18.sp)),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// YENİ YARDIMCI WIDGET
class FocusableField extends StatefulWidget {
  final Widget child;
  final bool autofocus;
  final bool isButton; // Butonlar için scale efekti eklemek için

  const FocusableField({
    super.key,
    required this.child,
    this.autofocus = false,
    this.isButton = false,
  });

  @override
  State<FocusableField> createState() => _FocusableFieldState();
}

class _FocusableFieldState extends State<FocusableField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: (widget.isButton && _isFocused) ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: _isFocused ? [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 8.0,
              spreadRadius: 2.0,
            )
          ] : [],
        ),
        child: Focus(
          autofocus: widget.autofocus,
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
            });
          },
          child: widget.child,
        ),
      ),
    );
  }
}