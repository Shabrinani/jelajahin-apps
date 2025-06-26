// Import pustaka utama Flutter dan warna dari konfigurasi global aplikasi
import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart';

/// Halaman NotificationPage berfungsi untuk menampilkan semua notifikasi aplikasi.
/// Menggunakan TabBar untuk memfilter berdasarkan tipe (All, System, User).
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  // Controller untuk mengatur tab navigasi antar jenis notifikasi
  late TabController _tabController;

  // Daftar notifikasi yang ditampilkan (data dummy)
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Selamat Datang di Jelajahin!',
      'subtitle': 'Terima kasih telah bergabung dengan Jelajahin. Yuk mulai eksplorasi!',
      'read': false, // Belum dibaca
      'type': 'system', // Tipe notifikasi: system
    },
    {
      'title': 'Postinganmu disukai!',
      'subtitle': 'Ada yang menyukai destinasi yang kamu bagikan.',
      'read': true,
      'type': 'user',
    },
    {
      'title': 'Update Aplikasi',
      'subtitle': 'Versi terbaru dari Jelajahin telah tersedia.',
      'read': false,
      'type': 'system',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Inisialisasi TabController dengan 3 tab (All, System, User)
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fungsi untuk memfilter daftar notifikasi sesuai tipe tab aktif
  List<Map<String, dynamic>> _filteredNotifications(String type) {
    if (type == 'all') return _notifications;
    return _notifications.where((n) => n['type'] == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // TabBar di bawah AppBar untuk filter jenis notifikasi
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryDark,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'System'),
            Tab(text: 'User'),
          ],
        ),
      ),
      // Konten body menggunakan TabBarView agar sinkron dengan TabBar
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList('all'),
          _buildNotificationList('system'),
          _buildNotificationList('user'),
        ],
      ),
    );
  }

  /// Menampilkan daftar notifikasi dalam bentuk ListView
  Widget _buildNotificationList(String type) {
    final filtered = _filteredNotifications(type);
    return ListView.separated(
      itemCount: filtered.length,
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notif = filtered[index];
        return InkWell(
          onTap: () {
            setState(() {
              notif['read'] = true; // Tandai sebagai sudah dibaca
            });

            // Notifikasi spesifik: tampilkan dialog jika notifikasi sambutan
            if (notif['title'] == 'Selamat Datang di Jelajahin!') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Selamat Datang!'),
                  content: const Text('Kami senang Anda bersama kami di Jelajahin!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    )
                  ],
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notif['read'] ? Colors.grey[100] : AppColors.lightTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notif['read'] ? Colors.grey[200]! : AppColors.lightTeal,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['title'],
                  style: TextStyle(
                    fontWeight: notif['read'] ? FontWeight.normal : FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notif['subtitle'],
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
