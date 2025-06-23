// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:jelajahin_apps/theme/colors.dart'; // Pastikan ini mengarah ke file AppColors Anda

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  // Data FAQ dibagi berdasarkan kategori
  final Map<String, List<Map<String, String>>> faqData = const {
    'Aplikasi Perjalanan': [ // Kategori 1 - Diterjemahkan
      {
        'question': 'Bagaimana cara mengatur Aplikasi Perjalanan saya?', // Diterjemahkan
        'answer': 'Untuk mengatur Aplikasi Perjalanan Anda, pertama-tama unduh dari App Store atau Google Play Store. Kemudian, ikuti petunjuk di layar untuk membuat akun Anda dan menyelesaikan proses pengaturan awal.', // Diterjemahkan
      },
      {
        'question': 'Bagaimana cara melindungi akun saya dengan kata sandi?', // Diterjemahkan
        'answer': 'Anda dapat mengatur kata sandi yang kuat selama pendaftaran. Untuk mengubah atau memperbarui kata sandi Anda, buka bagian "Edit Profil" di pengaturan Profil Anda dan cari opsi pengaturan ulang kata sandi.', // Diterjemahkan
      },
    ],
    'Menghubungkan & Membuat Lingkaran': [ // Kategori 2 - Diterjemahkan
      {
        'question': 'Jika saya pihak ketiga, bagaimana cara saya terhubung?', // Diterjemahkan
        'answer': 'Pihak ketiga dapat diundang ke dalam lingkaran oleh anggota yang sudah ada. Mereka akan menerima tautan undangan atau kode untuk bergabung dengan lingkaran tersebut.', // Diterjemahkan
      },
      {
        'question': 'Bagaimana cara menghapus atau memutuskan koneksi dari anggota?', // Diterjemahkan
        'answer': 'Untuk menghapus atau memutuskan koneksi dari anggota dalam suatu lingkaran, navigasikan ke pengaturan lingkaran dan pilih opsi untuk mengelola anggota. Anda akan menemukan pilihan untuk menghapus atau memutuskan koneksi individu.', // Diterjemahkan
      },
      {
        'question': 'Bagaimana cara membuat akun saya?', // Diterjemahkan
        'answer': 'Pembuatan akun dilakukan melalui opsi "Daftar" di halaman Login. Anda perlu memberikan email dan kata sandi untuk mendaftar.', // Diterjemahkan
      },
      {
        'question': 'Bagaimana cara memverifikasi akun saya?', // Diterjemahkan
        'answer': 'Verifikasi akun biasanya melibatkan konfirmasi alamat email Anda melalui tautan yang dikirimkan kepada Anda selama pendaftaran. Harap periksa kotak masuk dan folder spam Anda untuk email verifikasi.', // Diterjemahkan
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        // Tombol kembali disesuaikan agar konsisten
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryDark), // Ikon dan warna disesuaikan
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bantuan', // Judul App Bar diubah ke Bahasa Indonesia
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            fontSize: 20, // Menambahkan ukuran font untuk konsistensi
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loop melalui setiap kategori FAQ
            ...faqData.entries.map((entry) {
              String categoryTitle = entry.key;
              List<Map<String, String>> questions = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Kategori
                  Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(0.5), // Warna background untuk kategori lebih soft
                      borderRadius: BorderRadius.circular(10), // Sudut membulat
                    ),
                    child: Text(
                      categoryTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  // Daftar Pertanyaan dalam Kategori
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white, // Warna background putih agar menonjol
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [ // Menambahkan sedikit shadow untuk efek kartu
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2), // changes position of shadow
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                          iconColor: AppColors.darkTeal,
                          collapsedIconColor: AppColors.darkTeal,
                          title: Text(
                            questions[index]['question']!,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600, // Sedikit lebih tebal
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                              child: Text(
                                questions[index]['answer']!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[800],
                                  height: 1.5, // Spasi baris untuk keterbacaan
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}