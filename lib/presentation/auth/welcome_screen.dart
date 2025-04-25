import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  static const Color primaryColor = Color(0xFF7D91FA);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
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
                      SizedBox(height: screenHeight * 0.05),
                      // Logo text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Uni",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'SmoochSans',
                            ),
                          ),
                          Text(
                            "Verse",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              fontFamily: 'SmoochSans',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Logo icon
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA5B3FF).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/logos/logo.png',
                          height: screenWidth * 0.2,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.1),
                      // Botones
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize:
                                  Size(double.infinity, screenHeight * 0.06),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: primaryColor,
                            ),
                            child: Text(
                              "Log in",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              textStyle: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            child: Text(
                              "Create a new account",
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontFamily: 'Montserrat',
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          _socialButton(
                            icon: "assets/google.svg",
                            text: "Sign in with Google",
                            onTap: () {},
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          _socialButton(
                            icon: "assets/facebook.svg",
                            text: "Sign in with Facebook",
                            onTap: () {},
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.015, horizontal: screenWidth * 0.06),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              height: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
