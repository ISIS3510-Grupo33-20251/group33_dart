import 'package:flutter/material.dart';
import '../../services/api_service_adapter.dart';
import 'package:group33_dart/globals.dart';
import '../../services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  late final ApiServiceAdapter _apiService;
  late final ConnectivityService _connectivityService;
  bool _isLoading = false;
  String _passwordMatchMessage = '';
  static const Color primaryColor = Color(0xFF7D91FA);

  @override
  void initState() {
    super.initState();
    _apiService = ApiServiceAdapter(backendUrl: backendUrl);
    _connectivityService = ConnectivityService();
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
    _nameController.dispose();
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
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    // Check connectivity before attempting registration
    final hasConnection = await _connectivityService.checkConnectivity();
    if (!hasConnection) {
      await _connectivityService.showNoInternetDialog(context);
      return;
    }

    // Validar el correo electrónico
    String email = _emailController.text;
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email) ||
        email.contains(' ') ||
        email.contains(RegExp(r'[^\x00-\x7F]'))) {
      _showErrorSnackBar(
          'Please enter a valid email without spaces or emojis.');
      return;
    }

    // Validar el nombre si se proporcionó
    String? name = _nameController.text.trim();
    if (name.isNotEmpty && name.contains(' ')) {
      _showErrorSnackBar('Name cannot contain spaces');
      return;
    }

    // Validar la contraseña
    String password = _passwordController.text;
    if (password.trim().isEmpty ||
        password.contains(' ') ||
        password.contains(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true)) ||
        password.contains(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true)) ||
        password.length < 8) {
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
      final response = await _apiService.register(
        email,
        password,
        name: name.isEmpty ? null : name,
      );

      // Guardar información del usuario
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      await prefs.setString('userId', response['userId']);

      // Actualizar variables globales
      userId = response['userId'];
      token = response['token'];

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar al home después de un breve delay
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      String errorMessage;

      if (e.toString().contains("email already exists") ||
          e.toString().contains("already registered")) {
        errorMessage = "The email is already registered, please try again.";
      } else if (e.toString().contains("Failed to connect to server")) {
        errorMessage =
            "Unable to connect to the server. Please check your internet connection.";
      } else {
        errorMessage = "An unexpected error occurred. Please try again.";
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // Círculos decorativos
              Positioned(
                right: -screenWidth * 0.25,
                top: -screenHeight * 0.1,
                child: Container(
                  width: screenWidth * 0.8,
                  height: screenWidth * 0.8,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -screenWidth * 0.2,
                bottom: -screenHeight * 0.15,
                child: Container(
                  width: screenWidth * 0.7,
                  height: screenWidth * 0.7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA5B3FF).withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Contenido principal
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        color: Colors.grey[800],
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logo and title section
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Uni",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            fontFamily: 'SmoochSans',
                          ),
                        ),
                        const Text(
                          "Verse",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'SmoochSans',
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Image(
                          image: AssetImage('assets/logos/logo.png'),
                          height: 50,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Form section
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildInputField(
                          "Name (Optional)",
                          _nameController,
                          false,
                        ),
                        const SizedBox(height: 8),
                        buildInputField(
                          "Email",
                          _emailController,
                          false,
                        ),
                        const SizedBox(height: 8),
                        buildInputField(
                          "Password",
                          _passwordController,
                          true,
                        ),
                        const SizedBox(height: 8),
                        buildInputField(
                          "Confirm Password",
                          _confirmPasswordController,
                          true,
                        ),
                        if (_passwordMatchMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _passwordMatchMessage,
                              style: TextStyle(
                                color:
                                    _passwordMatchMessage == 'Passwords match'
                                        ? Colors.green
                                        : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Button section
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: primaryColor,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Sign up",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
    String label,
    TextEditingController controller,
    bool isPassword,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            fontFamily: 'Montserrat',
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
