import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_viewmodel.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  static const Color primaryColor = Color(0xFF7D91FA);

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      // Here you would typically save the token
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setString('token', response['token']);

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Círculos decorativos
          Positioned(
            right: -100,
            top: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFA5B3FF).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      color: Colors.grey[800],
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Logo
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "Uni",
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        "Verse",
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(height: 40),
                      // Logo image
                      Image(
                        image: AssetImage('assets/logos/logo.png'),
                        height: 120,
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                  // Login Fields
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email or Username",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: primaryColor,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Log in",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



