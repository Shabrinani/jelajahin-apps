import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/main.dart'; // Import main.dart for AppColors and global theme access
import 'package:jelajahin_apps/pages/login.dart'; // Import login page
// Google Fonts is no longer needed directly here since it's configured in main.dart

class RegisterPage extends StatefulWidget {
  final Function(String, String) onRegister;

  const RegisterPage({super.key, required this.onRegister});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController(); // This will be used as email for Firebase
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypePasswordController = TextEditingController();

  bool showPassword = false;
  bool showRetypePassword = false;
  bool acceptTerms = false;

  void showCustomDialog(String title, String message, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          // Using Theme.of(context).textTheme directly, as Poppins is set globally
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          message,
          // Using Theme.of(context).textTheme directly
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.black,
          ),
        ),
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

  void register() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim(); // This is the email for Firebase
    final password = passwordController.text;
    final retypePassword = retypePasswordController.text;

    if (name.isEmpty || username.isEmpty || password.isEmpty || retypePassword.isEmpty) {
      showCustomDialog("Gagal", "Semua kolom harus diisi.");
      return;
    }

    if (password != retypePassword) {
      showCustomDialog("Gagal", "Kata sandi tidak cocok!");
      return;
    }

    if (!acceptTerms) {
      showCustomDialog("Gagal", "Anda harus menyetujui syarat dan ketentuan.");
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: username, // 'username' is used as 'email' for Firebase
        password: password,
      );

      widget.onRegister(username, password);

      showCustomDialog("Berhasil", "Registrasi berhasil!", onConfirm: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan yang tidak diketahui.";
      if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi yang diberikan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Akun sudah ada untuk email tersebut.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }
      showCustomDialog("Gagal", "Registrasi gagal: $errorMessage");
    } catch (e) {
      showCustomDialog("Gagal", "Terjadi kesalahan saat registrasi: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the TextTheme from the global theme
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'images/logo_jelajahin.png', // Ensure this path is correct
                    width: 70,
                    height: 70,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // "Let's Get Started"
              Text(
                'Let\'s Get Started',
                // Using textTheme directly. Poppins is already applied globally.
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'create your new account and find more beautiful destinations',
                textAlign: TextAlign.center,
                // Using textTheme directly.
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Input Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Name',
                  // Using textTheme directly.
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Enter your full name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Input Username (Used as Email for Firebase)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email (for login)', // Clarified label for clarity
                  // Using textTheme directly.
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usernameController,
                keyboardType: TextInputType.emailAddress, // Ensure email keyboard type
                decoration: InputDecoration(
                  hintText: "Enter your email", // Change hint text to reflect email
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Input Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  // Using textTheme directly.
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
                    borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 20),

              // Input Re-type Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Re-type Password',
                  // Using textTheme directly.
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: retypePasswordController,
                obscureText: !showRetypePassword,
                decoration: InputDecoration(
                  hintText: "Re-type your password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showRetypePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        showRetypePassword = !showRetypePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Accept Term of Service
              Row(
                children: [
                  Checkbox(
                    value: acceptTerms,
                    onChanged: (bool? newValue) {
                      setState(() {
                        acceptTerms = newValue!;
                      });
                    },
                    activeColor: AppColors.lightTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  Text(
                    'Accept term of service',
                    // Using textTheme directly.
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: AppColors.lightTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Sign Up",
                    // Using textTheme directly.
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Already have an account? Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    // Using textTheme directly.
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: Text(
                      'Sign In',
                      // Using textTheme directly.
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