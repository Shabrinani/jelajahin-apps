// Import pustaka untuk akses file, Firebase, dan utilitas Flutter
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Kelas utama FirestoreService untuk mengatur interaksi ke Firebase:
/// - Firestore (database)
/// - Firebase Auth (akun pengguna)
/// - Firebase Storage (unggah gambar)
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // =======================================================================
  // == User Methods: Mengelola data pengguna ==
  // =======================================================================

  /// Mengambil data pengguna yang sedang login (hanya 1 kali)
  Future<DocumentSnapshot> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _db.collection('users').doc(user.uid).get();
    }
    throw Exception("No user logged in");
  }

  /// Mendapatkan data pengguna secara real-time (snapshots)
  Stream<DocumentSnapshot> getUserStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _db.collection('users').doc(user.uid).snapshots();
    }
    return const Stream.empty();
  }

  /// Membuat data pengguna baru di Firestore saat register/login pertama kali
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String profilePictureUrl,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'profile_picture_url': profilePictureUrl,
      'joined_at': FieldValue.serverTimestamp(),
      'saved_posts_ids': [], // Untuk bookmark destinasi
    });
  }

  /// Memperbarui profil pengguna (nama, avatar, no HP, gender, dll)
  Future<void> updateUserProfile({
    required String name,
    String? profilePictureUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    if (name.trim() != (user.displayName ?? '')) {
      await user.updateDisplayName(name.trim());
    }

    final Map<String, dynamic> dataToUpdate = {
      'name': name.trim(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (profilePictureUrl != null)
      dataToUpdate['profile_picture_url'] = profilePictureUrl;
    if (phoneNumber != null) dataToUpdate['phoneNumber'] = phoneNumber.trim();
    dataToUpdate['dateOfBirth'] =
        dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : FieldValue.delete();
    dataToUpdate['gender'] =
        (gender != null && gender.isNotEmpty) ? gender : FieldValue.delete();

    await _db
        .collection('users')
        .doc(user.uid)
        .set(dataToUpdate, SetOptions(merge: true));
  }

  // =======================================================================
  // == Destination Methods: Menangani unggah, ambil, hapus tempat wisata ==
  // =======================================================================

  /// Menambahkan destinasi baru (unggah gambar ke Storage + data ke Firestore)
  Future<void> addDestination({
    required XFile imageFile,
    required Uint8List webImageBytes,
    required String title,
    required String location,
    required String description,
    required String category,
    required double rating,
    required double latitude,
    required double longitude,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User tidak login.');

    // Buat nama file gambar berdasarkan timestamp dan UID
    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.uid}';
    Reference storageRef = _storage.ref().child('destinations/$fileName');

    // Upload gambar ke Firebase Storage (web dan mobile dibedakan)
    UploadTask uploadTask = kIsWeb
        ? storageRef.putData(webImageBytes)
        : storageRef.putFile(File(imageFile.path));
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    // Ambil info pengguna (nama & foto profil) untuk disimpan bersama destinasi
    DocumentSnapshot userDoc = await getCurrentUserData();
    String ownerName = userDoc.get('name') ?? 'Anonim';
    String ownerAvatar = userDoc.get('profile_picture_url') ?? 'https://via.placeholder.com/150';

    // Simpan data destinasi ke Firestore
    await _db.collection('destinations').add({
      'title': title,
      'location': location,
      'description': description,
      'imageUrl': downloadUrl,
      'category': category,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'likes': [],
      'commentCount': 0,
    });
  }

  /// Memperbarui data destinasi berdasarkan ID
  Future<void> updateDestination(
      String destinationId, Map<String, dynamic> data) async {
    await _db.collection('destinations').doc(destinationId).update(data);
  }

  /// Mengambil satu destinasi berdasarkan ID (hanya satu kali, bukan stream)
  Future<DocumentSnapshot> getDestinationById(String destinationId) {
    return _db.collection('destinations').doc(destinationId).get();
  }

  /// Menghapus destinasi (belum menghapus gambar & komentar)
  Future<void> deleteDestination(String destinationId) async {
    // TODO: Hapus juga gambar dari Firebase Storage dan sub-koleksi komentar
    await _db.collection('destinations').doc(destinationId).delete();
  }

  /// Mendapatkan semua destinasi sebagai stream (real-time update)
  Stream<List<Map<String, dynamic>>> getDestinationsStream() {
    return _db
        .collection('destinations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              // Validasi agar tidak error saat dipakai di UI
              if (data['likes'] is! List) data['likes'] = [];
              if (data['commentCount'] is! int) data['commentCount'] = 0;
              return data;
            }).toList());
  }

  /// Mendapatkan 1 destinasi sebagai stream (untuk detail halaman)
  Stream<DocumentSnapshot> getDestinationStream(String destinationId) {
    return _db.collection('destinations').doc(destinationId).snapshots();
  }

  /// Stream daftar destinasi yang disimpan (bookmark) oleh pengguna
  Stream<List<Map<String, dynamic>>> getSavedDestinationsStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
          if (!userDoc.exists || userDoc.data()?['saved_posts_ids'] == null)
            return [];
          final List<dynamic> savedPostIds = userDoc.data()!['saved_posts_ids'];
          if (savedPostIds.isEmpty) return [];
          final destinationsSnapshot = await _db
              .collection('destinations')
              .where(FieldPath.documentId, whereIn: savedPostIds)
              .get();
          return destinationsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            if (data['likes'] is! List) data['likes'] = [];
            if (data['commentCount'] is! int) data['commentCount'] = 0;
            return data;
          }).toList();
        });
  }

  /// Mendapatkan hanya destinasi yang dibuat oleh user saat ini
  Stream<List<Map<String, dynamic>>> getUserPostsStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _db
        .collection('destinations')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              if (data['likes'] is! List) data['likes'] = [];
              if (data['commentCount'] is! int) data['commentCount'] = 0;
              return data;
            }).toList());
  }

  // =======================================================================
  // == Interactive Methods: Like & Bookmark ==
  // =======================================================================

  /// Menyukai / batal menyukai destinasi
  Future<void> toggleLike(String destinationId, bool isLiked) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    DocumentReference destinationRef = _db.collection('destinations').doc(destinationId);
    final update = isLiked
        ? FieldValue.arrayRemove([user.uid])
        : FieldValue.arrayUnion([user.uid]);
    await destinationRef.update({'likes': update});
  }

  /// Menyimpan / batal menyimpan destinasi ke bookmark user
  Future<void> toggleBookmark(String destinationId, bool isBookmarked) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    DocumentReference userRef = _db.collection('users').doc(user.uid);
    final update = isBookmarked
        ? FieldValue.arrayRemove([destinationId])
        : FieldValue.arrayUnion([destinationId]);
    await userRef.update({'saved_posts_ids': update});
  }

  // =======================================================================
  // == Comment Methods ==
  // =======================================================================

  /// Mengambil komentar dari sub-koleksi comments berdasarkan destinasi
  Stream<QuerySnapshot> getCommentsStream(String destinationId) {
    return _db
        .collection('destinations')
        .doc(destinationId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Menambahkan komentar baru pada destinasi + update commentCount
  Future<void> addComment({
    required String noteId,
    required String text,
    required String userId,
    String? parentCommentId,
  }) async {
    try {
      DocumentReference destinationRef = _db.collection('destinations').doc(noteId);
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();

      String userName = userDoc.get('name') ?? 'Anonim';
      String userAvatar = userDoc.get('profile_picture_url') ?? 'https://via.placeholder.com/150';
      String userEmail = userDoc.get('email') ?? 'anonim';

      // Simpan komentar ke sub-koleksi 'comments'
      await destinationRef.collection('comments').add({
        'text': text,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'userAvatar': userAvatar,
        'timestamp': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
        'likes': [], // Inisialisasi array likes
      });

      // Tambahkan counter komentar +1
      await destinationRef.update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      print("---!!! TERJADI ERROR PADA FUNGSI addComment !!!---");
      print("ERROR: ${e.toString()}");
    }
  }
}
