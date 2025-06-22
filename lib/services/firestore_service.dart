import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // =======================================================================
  // == User Methods ==
  // =======================================================================

  Future<DocumentSnapshot> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _db.collection('users').doc(user.uid).get();
    }
    throw Exception("No user logged in");
  }

  Stream<DocumentSnapshot> getUserStream() {
    User? user = _auth.currentUser;
    if (user != null) {
      return _db.collection('users').doc(user.uid).snapshots();
    }
    return const Stream.empty();
  }

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
      'saved_posts_ids': [],
    });
  }

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
  // == Destination (Post) Methods ==
  // =======================================================================

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

    String fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.uid}';
    Reference storageRef = _storage.ref().child('destinations/$fileName');

    UploadTask uploadTask = kIsWeb
        ? storageRef.putData(webImageBytes)
        : storageRef.putFile(File(imageFile.path));
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    DocumentSnapshot userDoc = await getCurrentUserData();
    String ownerName = userDoc.get('name') ?? 'Anonim';
    String ownerAvatar = userDoc.get('profile_picture_url') ??
        'https://via.placeholder.com/150';

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

  Future<void> updateDestination(
      String destinationId, Map<String, dynamic> data) async {
    await _db.collection('destinations').doc(destinationId).update(data);
  }

  Future<void> deleteDestination(String destinationId) async {
    // TODO: Hapus juga gambar dari Firebase Storage dan sub-koleksi komentar
    await _db.collection('destinations').doc(destinationId).delete();
  }

  // ===== INI BAGIAN PENTINGNYA =====
  // Fungsi ini sudah menggunakan .snapshots(), yang artinya akan otomatis
  // mengirim data terbaru setiap kali ada perubahan di Firestore.
  // Ini adalah metode yang benar untuk membuat UI Anda reaktif.
  Stream<List<Map<String, dynamic>>> getDestinationsStream() {
    return _db
        .collection('destinations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Sudah menyertakan ID dokumen, bagus!
              // Melakukan validasi tipe data, ini praktik yang sangat baik.
              if (data['likes'] is! List) data['likes'] = [];
              if (data['commentCount'] is! int) data['commentCount'] = 0;
              return data;
            }).toList());
  }

  Stream<DocumentSnapshot> getDestinationStream(String destinationId) {
    return _db.collection('destinations').doc(destinationId).snapshots();
  }

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
  // == Interactive Methods ==
  // =======================================================================

  Future<void> toggleLike(String destinationId, bool isLiked) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    DocumentReference destinationRef =
        _db.collection('destinations').doc(destinationId);
    final update = isLiked
        ? FieldValue.arrayRemove([user.uid])
        : FieldValue.arrayUnion([user.uid]);
    await destinationRef.update({'likes': update});
  }

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

  Stream<QuerySnapshot> getCommentsStream(String destinationId) {
    return _db
        .collection('destinations')
        .doc(destinationId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Fungsi ini sudah benar, yaitu menaikkan `commentCount` setiap kali ada comment baru.
  Future<void> addComment(
      {required String noteId,
      required String text,
      required String userId,
      String? parentCommentId}) async {
    DocumentReference destinationRef = _db.collection('destinations').doc(noteId);
    DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
    String userName = userDoc.get('name') ?? 'Anonim';
    String userAvatar = userDoc.get('profile_picture_url') ??
        'https://via.placeholder.com/150';
    String userEmail = userDoc.get('email') ?? 'anonim';
    await destinationRef.collection('comments').add({
      'text': text,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userAvatar': userAvatar,
      'timestamp': FieldValue.serverTimestamp(),
      'parentCommentId': parentCommentId,
      'likes': [],
    });
    await destinationRef.update({'commentCount': FieldValue.increment(1)});
  }
}