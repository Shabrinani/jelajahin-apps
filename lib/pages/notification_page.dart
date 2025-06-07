// lib/pages/notification_page.dart
import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          "Your latest notifications will appear here.",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}