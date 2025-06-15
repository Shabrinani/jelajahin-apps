import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:jelajahin_apps/pages/home.dart'; // Ensure this path is correct for your Home page
import 'package:jelajahin_apps/pages/register.dart';
// Import theme/colors.dart directly for AppColors
import 'package:jelajahin_apps/theme/colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;
  bool rememberMe = false;
  bool _isLoading = false; // State for loading indicator

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

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // 1. Authenticate user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: inputEmail,
        password: inputPassword,
      );

      // 2. After successful authentication, get the current user
      User? currentUser = userCredential.user;

      if (currentUser != null) {
        // 3. (OPTIONAL but Recommended) Fetch user data from Firestore
        //    This step is crucial if you need to display user's name, profile picture, etc.,
        //    immediately after login.
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // Data user ditemukan, Anda bisa mengaksesnya seperti ini:
          // String? userName = userDoc.get('name');
          // String? profilePictureUrl = userDoc.get('profile_picture_url');
          // print("Logged in user name: $userName");
          // print("Logged in user profile picture: $profilePictureUrl");
          // Anda bisa menyimpan data ini di provider (seperti Provider, Riverpod, Bloc)
          // atau meneruskannya ke halaman Home jika diperlukan.
        } else {
          // Jika dokumen user tidak ditemukan setelah login (kasus jarang, tapi mungkin jika ada inkonsistensi)
          print("Warning: User document not found for UID: ${currentUser.uid}");
          // Anda bisa memutuskan untuk logout otomatis atau tetap melanjutkan, tergantung UX Anda.
          // showCustomDialog("Error", "Data profil Anda tidak ditemukan. Silakan coba lagi atau hubungi dukungan.");
          // await FirebaseAuth.instance.signOut();
          // return;
        }

        // 4. If successful and data fetched (or not needed immediately), navigate to the Home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } else {
        // This case should ideally not happen if signInWithEmailAndPassword succeeds
        showCustomDialog("Login Gagal", "Terjadi kesalahan: Data pengguna tidak ditemukan setelah autentikasi.");
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Terjadi kesalahan saat login.";
      if (e.code == 'user-not-found') {
        errorMessage = 'Tidak ada akun terdaftar dengan email ini.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Kata sandi salah. Silakan coba lagi.';
      } else if (e.code == 'invalid-credential') { // More generic for newer Firebase versions
        errorMessage = 'Kredensial tidak valid (email atau kata sandi salah).';
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
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator regardless of success or failure
      });
    }
  }

  // Method to handle "Forgot Password"
  void _resetPassword() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController resetEmailController = TextEditingController();
        return AlertDialog(
          title: Text("Reset Kata Sandi", style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          )),
          content: TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Masukkan Email Anda",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark, // Custom color for cancel
              ),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                String email = resetEmailController.text.trim();
                if (email.isEmpty) {
                  Navigator.pop(context); // Close current dialog first
                  showCustomDialog("Error", "Email tidak boleh kosong.");
                  return;
                }
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(context); // Close the dialog
                  showCustomDialog("Berhasil", "Link reset kata sandi telah dikirim ke email Anda.");
                } on FirebaseAuthException catch (e) {
                  Navigator.pop(context); // Close the dialog
                  showCustomDialog("Error", "Gagal mengirim link reset: ${e.message}");
                } catch (e) {
                  Navigator.pop(context); // Close the dialog
                  showCustomDialog("Error", "Terjadi kesalahan tak terduga: ${e.toString()}");
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.lightTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Kirim"),
            ),
          ],
        );
      },
    );
  }

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(
          onRegister: (username, password) {
            // This callback is handled in RegisterPage directly,
            // so no further Firebase action is needed here.
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
                  'Email',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your email",
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
                    onPressed: _resetPassword, // Call the new reset password method
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
                  onPressed: _isLoading ? null : login, // Disable button when loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white) // Show loading indicator
                      : Text(
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