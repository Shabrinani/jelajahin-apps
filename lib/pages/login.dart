import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'home.dart';
import 'register.dart';
import 'package:jelajahin_apps/main.dart'; // Import main.dart for AppColors

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // We'll use emailController, as Firebase Auth primarily uses email for login
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;
  bool rememberMe = false; // Added back for UI completeness

  // Custom dialog function, consistent with RegisterPage's styling
  void showCustomDialog(String title, String message, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        )),
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.black,
        )),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onConfirm != null) onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.lightTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Login method with Firebase Authentication
  void login() async {
    String inputEmail = emailController.text.trim();
    String inputPassword = passwordController.text;

    if (inputEmail.isEmpty || inputPassword.isEmpty) {
      showCustomDialog("Login Gagal", "Email dan Kata Sandi harus diisi.");
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: inputEmail,
        password: inputPassword,
      );

      // If successful, navigate to the Home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan saat login.";
      if (e.code == 'user-not-found') {
        errorMessage = 'Tidak ada akun terdaftar dengan email ini.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Kata sandi salah. Silakan coba lagi.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Terlalu banyak upaya login. Coba lagi nanti.';
      } else {
        errorMessage = 'Login gagal: ${e.message}'; // Generic message for other Firebase errors
      }
      showCustomDialog("Login Gagal", errorMessage);
    } catch (e) {
      // Catch any other unexpected errors
      showCustomDialog("Login Gagal", "Terjadi kesalahan tak terduga: ${e.toString()}");
    }
  }

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(
          onRegister: (username, password) {
            // This callback is triggered when registration in RegisterPage is successful.
            // Since RegisterPage handles Firebase user creation directly, this callback
            // here can optionally be used to, for example, log the user in immediately
            // after registration, or simply confirm success.
            // For now, after successful registration, RegisterPage navigates back to login.
            // So, this callback doesn't need to do anything with Firebase here.
            // If you want auto-login, you can call login() here with the provided credentials.
            // Example: login(); // this would attempt to login with the registered credentials
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Aplikasi
              Image.asset(
                'images/logo_jelajahin.png', // Ensure this path is correct
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),

              // Welcome Back!
              Text(
                'Welcome Back !',
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),

              // Slogan
              Text(
                'Stay signed in with your account to make searching easier',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // TextField Email Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email', // Label now explicitly "Email"
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController, // Using emailController
                keyboardType: TextInputType.emailAddress, // Ensure email keyboard type
                decoration: InputDecoration(
                  hintText: "Enter your email", // Hint text updated for email
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 20),

              // TextField Password Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // "Keep me signed in" and "Forgot password?"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: rememberMe,
                          onChanged: (bool? newValue) {
                            setState(() {
                              rememberMe = newValue!;
                            });
                          },
                          activeColor: AppColors.lightTeal,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Text(
                        'Keep me signed in',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement Forgot Password with Firebase password reset
                      print("Forgot Password tapped");
                      showCustomDialog("Fitur Belum Tersedia", "Fitur lupa kata sandi akan segera hadir!");
                    },
                    child: Text(
                      'Forgot password?',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 14,
                        color: AppColors.lightTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Login",
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "You don't have an account?",
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  TextButton(
                    onPressed: goToRegister,
                    child: Text(
                      'Sign Up',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 14,
                        color: AppColors.lightTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}