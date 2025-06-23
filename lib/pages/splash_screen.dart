// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:jelajahin_apps/pages/login.dart';
import 'package:jelajahin_apps/main.dart'; // Import main.dart untuk mengakses AppColors

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Akses textTheme dari tema global
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white, // Latar belakang putih dari AppColors
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pastikan Anda sudah menambahkan logo di pubspec.yaml
            Image.asset(
              'images/logo_jelajahin.png', // Sesuaikan dengan path logo Anda
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              'Jelajahin',
              // Menggunakan salah satu gaya headline dari tema
              // dan menimpa properti yang spesifik
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.black, // Warna teks jadi hitam
                fontSize: 36,          // Sesuaikan ukuran font
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ) ?? const TextStyle( // Fallback jika headlineMedium null
                color: AppColors.black,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Temukan petualanganmu selanjutnya',
              // Menggunakan salah satu gaya body dari tema
              // dan menimpa properti yang spesifik
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.black, // Warna teks dari palet Anda
                fontSize: 16,               // Sesuaikan ukuran font
              ) ?? const TextStyle( // Fallback jika bodyLarge null
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