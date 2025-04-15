import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:group33_dart/globals.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _passwordMatchMessage = '';
  static const Color primaryColor = Color(0xFF7D91FA);

  @override
  void initState() {
    super.initState();
    // Agregar listeners para verificar las contraseñas en tiempo real
    _passwordController.addListener(_checkPasswords);
    _confirmPasswordController.addListener(_checkPasswords);
  }

  @override
  void dispose() {
    // Limpiar los controllers cuando se destruye el widget
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswords() {
    if (_passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty) {
      setState(() {
        if (_passwordController.text == _confirmPasswordController.text) {
          _passwordMatchMessage = 'Passwords match';
        } else {
          _passwordMatchMessage = 'Passwords do not match';
        }
      });
    } else {
      setState(() {
        _passwordMatchMessage = '';
      });
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar('Please fill all fields');
      return;
    }

    // Validar el correo electrónico
    String email = _emailController.text;
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email) ||
        email.contains(' ') ||
        email.contains(RegExp(r'[^\x00-\x7F]'))) {
      // Verifica caracteres no ASCII
      _showErrorSnackBar(
          'Please enter a valid email without spaces or emojis.');
      return;
    }

    // Validar la contraseña
    String password = _passwordController.text;
    if (password.trim().isEmpty || // Verifica que no sea solo espacios
        password.contains(' ') ||
        password.contains(RegExp(r'[\u{1F600}-\u{1F64F}]',
            unicode: true)) || // Rango de emojis
        password.contains(RegExp(r'[\u{1F300}-\u{1F5FF}]',
            unicode: true)) || // Otro rango de emojis
        password.length < 8) {
      // Longitud mínima de 8 caracteres
      _showErrorSnackBar(
          'Password must be at least 8 characters long and cannot contain spaces or emojis.');
      return;
    }

    // Comparar contraseñas
    if (password != _confirmPasswordController.text) {
      _passwordMatchMessage = 'Passwords do not match';
      setState(() {});
      return;
    } else {
      _passwordMatchMessage = 'Passwords match';
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.register(
        email,
        password,
      );

      userId = response["userId"];

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      String errorMessage;

      // Verifica si el error es específico
      if (e.toString().contains("email already exists") ||
          e.toString().contains("already registered")) {
        errorMessage = "The email is already registered, please try again.";
      } else if (e.toString().contains("Failed to connect to server")) {
        errorMessage =
            "Unable to connect to the server. Please check your internet connection.";
      } else {
        errorMessage =
            "An unexpected error occurred. Please try again."; // Mensaje genérico
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                message,
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ],
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                              fontFamily: 'SmoochSans',
                            ),
                          ),
                          Text(
                            "Verse",
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              fontFamily: 'SmoochSans',
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
                      const SizedBox(height: 40),
                      // Register Fields
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Email",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
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
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Confirm Password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                          Text(
                            _passwordMatchMessage,
                            style: TextStyle(
                              color: _passwordMatchMessage == 'Passwords match'
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Register Button
                          ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: primaryColor,
                            ),
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
