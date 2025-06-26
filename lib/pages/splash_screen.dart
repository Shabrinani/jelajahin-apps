// Import pustaka Flutter dan halaman login tujuan setelah splash
import 'package:flutter/material.dart';
import 'package:jelajahin_apps/pages/login.dart';
import 'package:jelajahin_apps/main.dart';

/// Halaman pembuka (SplashScreen) yang ditampilkan selama 3 detik.
/// Menampilkan logo, nama aplikasi, dan tagline sebelum diarahkan ke LoginPage.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Setelah 3 detik, pindah otomatis ke halaman Login
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white, // Background putih sesuai tema aplikasi
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi
            Image.asset(
              'images/logo_jelajahin.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),

            // Judul aplikasi "Jelajahin"
            Text(
              'Jelajahin',
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.black,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ) ?? const TextStyle(
                color: AppColors.black,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            // Tagline aplikasi
            Text(
              'Temukan petualanganmu selanjutnya',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.black,
                fontSize: 16,
              ) ?? const TextStyle(
                color: AppColors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
