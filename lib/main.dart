import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'firebase_options.dart'; // Pastikan file ini ada di lib/
import 'pages/splash_screen.dart'; // Pastikan path ini benar

// Definisi AppColors dipindahkan ke sini agar bisa diakses global
class AppColors {
  static const Color primaryDark = Color(0xFF160F29); // Dark Blue/Purple
  static const Color darkTeal = Color(0xFF246A73);    // Teal/Turquoise
  static const Color lightTeal = Color(0xFF368F8B);  // Darker Teal/Green
  static const Color lightBrown = Color(0xFFF3DFC1); // Light Cream/Beige
  static const Color darkBrown = Color(0xFFDDBEA8);  // Light Brown/Tan

  static const Color black = Colors.black;
  static const Color white = Colors.white;
}

void main() async {
  // Pastikan binding Flutter sudah diinisialisasi sebelum memanggil native code (seperti Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Terapkan tema global di sini
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lightTeal),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white, // Menggunakan AppColors.white untuk background scaffold default
        // Konfigurasi Poppins untuk TextTheme
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme, // Menggunakan textTheme yang sudah ada sebagai dasar
        ),
      ),
      // Atur home ke SplashScreen, dan SplashScreen akan navigasi ke LoginPage
      home: const SplashScreen(),
      // Atau langsung ke LoginPage jika SplashScreen tidak lagi diperlukan
      // home: const LoginPage(),
    );
  }
}