import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import theme/colors.dart directly for AppColors
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/pages/login.dart'; // Import login page

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
  bool _isLoading = false; // State for loading indicator

  // Default profile picture URL (replace with your actual default image URL)
  // You might want to upload a default image to Firebase Storage and get its download URL.
  // For now, I'll use a placeholder.
  static const String _defaultProfilePictureUrl =
      'https://firebasestorage.googleapis.com/v0/b/jelajahin-apps.appspot.com/o/default_profile_picture.png?alt=media&token=YOUR_GENERATED_TOKEN'; // <--- PERHATIAN: Ganti dengan URL gambar default Anda

  void showCustomDialog(String title, String message, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        content: Text(
          message,
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

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // 1. Register user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: username, // 'username' is used as 'email' for Firebase
        password: password,
      );

      // 2. Get the newly created user's UID
      String? userId = userCredential.user?.uid;

      if (userId != null) {
        // 3. Save additional user data to Cloud Firestore
        // We'll create a document in a 'users' collection with the user's UID as the document ID.
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'uid': userId, // Menambahkan UID di dalam dokumen juga untuk kemudahan query (sesuai DB schema)
          'name': name,
          'email': username, // Menyimpan email juga untuk referensi (sesuai DB schema)
          'profile_picture_url': _defaultProfilePictureUrl, // Menggunakan URL default yang telah ditentukan
          'joined_at': FieldValue.serverTimestamp(), // Timestamp kapan user dibuat (sesuai DB schema)
          'saved_posts_ids': [], // Array kosong untuk postingan yang disimpan (sesuai DB schema)
        });

        // Inform the parent widget about successful registration (if needed for specific flow)
        widget.onRegister(username, password);

        showCustomDialog("Berhasil", "Registrasi berhasil!", onConfirm: () {
          // Navigate to the login page after successful registration and data saving
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        });
      } else {
        // This case should ideally not happen if createUserWithEmailAndPassword succeeds
        showCustomDialog("Gagal", "Terjadi kesalahan: UID pengguna tidak ditemukan.");
      }
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
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator regardless of success or failure
      });
    }
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
                  'Email (for login)',
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
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Enter your email",
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
                  onPressed: _isLoading ? null : register, // Disable button when loading
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
                          "Sign Up",
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
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