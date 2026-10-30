import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../services/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  Future<void> login() async {
    // Check empty fields
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Open SQLite database
      final db = await DatabaseHelper.instance.database;

      // Search user in users table
      final List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
        limit: 1,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // User found
      if (users.isNotEmpty) {
        await UserSession.saveUser(
          userId: users.first['id'] as int,
          name: users.first['name'] as String,
          email: users.first['email'] as String,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful')));

        // Open Home Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // User not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login error: $e')));
    }
  }

  // ----------------------------------------------------------
  // BUILD LOGIN PAGE
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  // ------------------------------------------------
                  // LOGO
                  // ------------------------------------------------
                  Container(
                    width: 80,
                    height: 80,

                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: const Icon(
                      Icons.newspaper_rounded,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to Local News & Alerts',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 35),

                  // ------------------------------------------------
                  // EMAIL
                  // ------------------------------------------------
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,

                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',

                      prefixIcon: const Icon(Icons.email_outlined),

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ------------------------------------------------
                  // PASSWORD
                  // ------------------------------------------------
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,

                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',

                      prefixIcon: const Icon(Icons.lock_outline),

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },

                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // FORGOT PASSWORD
                  // ------------------------------------------------
                  Align(
                    alignment: Alignment.centerRight,

                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password recovery will be added later.',
                            ),
                          ),
                        );
                      },

                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ------------------------------------------------
                  // LOGIN BUTTON
                  // ------------------------------------------------
                  SizedBox(
                    height: 55,

                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,

                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ------------------------------------------------
                  // REGISTER
                  // ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },

                        child: const Text(
                          'Register',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
