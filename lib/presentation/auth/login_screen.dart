import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.login(
      _emailController.text,
      _passwordController.text,
    );

    final message = success
        ? 'Login Successful! 🎉'
        : 'Login Failed! ❌ Please check your credentials.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      print("✅ Login success!");
    } else {
      print("❌ Login failed. Incorrect email or password.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Logo
              const Text(
                "Uni",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
              ),
              const Text(
                "Verse",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 40),

              // Login Fields
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Email", style: TextStyle(fontSize: 18)),
              ),
              TextField(controller: _emailController),
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Password", style: TextStyle(fontSize: 18)),
              ),
              TextField(controller: _passwordController, obscureText: true),
              const SizedBox(height: 24),

              // Login Button
              authViewModel.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(screenWidth * 0.8, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Log-in"),
              ),
              const SizedBox(height: 16),

              // Log-in & Sign-up options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text("Create a new account"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Expanded(
              //       child: _socialLoginButton(
              //         icon: "assets/google.svg",
              //         text: "Sign in with Google",
              //         onTap: () {},
              //         isSvg: true,
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 12),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Expanded(
              //       child: _socialLoginButton(
              //         icon: "assets/facebook.svg",
              //         text: "Sign in with Facebook",
              //         onTap: () {},
              //         isSvg: true, // Agregamos esta nueva propiedad
              //       ),
              //     ),
              //   ],
              // ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _socialLoginButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
    bool isSvg = false, // Add this parameter
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSvg
                ? SvgPicture.asset(icon, height: 24)  // Correct way to load SVG
                : Image.asset(icon, height: 24),     // Loads PNG/JPG normally
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
  }



