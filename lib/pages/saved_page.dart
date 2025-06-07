// lib/pages/saved_page.dart
import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Saved Trips',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          "Content for Saved Trips will go here.",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}