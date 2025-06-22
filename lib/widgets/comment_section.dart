import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/widgets/comment_card.dart';

class CommentSection extends StatefulWidget {
  final String noteId;
  final User? currentUser;
  final List<QueryDocumentSnapshot> comments;
  final FirestoreService firestoreService;

  const CommentSection({
    super.key,
    required this.noteId,
    required this.firestoreService,
    required this.currentUser,
    required this.comments,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  String? _replyingToCommentId;
  String? _replyingToUserEmail;

  void _postComment() {
    if (_commentController.text.trim().isEmpty || widget.currentUser == null) return;

    widget.firestoreService.addComment(
      noteId: widget.noteId,
      text: _commentController.text,
      userId: widget.currentUser!.uid,
      parentCommentId: _replyingToCommentId,
    );

    _commentController.clear();
    _cancelReply();
  }

  void _startReply(String commentId, String userEmail) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserEmail = userEmail;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserEmail = null;
    });
    FocusScope.of(context).unfocus();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topLevelComments = <QueryDocumentSnapshot>[];
    final replies = <String, List<QueryDocumentSnapshot>>{};

    for (var comment in widget.comments) {
      final data = comment.data() as Map<String, dynamic>;
      final parentId = data['parentCommentId'] as String?;

      if (parentId == null) {
        topLevelComments.add(comment);
      } else {
        (replies[parentId] ??= []).add(comment);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komentar (${widget.comments.length})',
          style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildCommentInputField(),
        const SizedBox(height: 32),
        if (topLevelComments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text("Jadilah yang pertama berkomentar!"),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topLevelComments.length,
            itemBuilder: (context, index) {
              final comment = topLevelComments[index];
              final commentReplies = replies[comment.id] ?? [];
              return CommentCard(
                noteId: widget.noteId,
                comment: comment,
                replies: commentReplies,
                onReply: _startReply,
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 32, indent: 16, endIndent: 16),
          ),
      ],
    );
  }

  Widget _buildCommentInputField() {
    const Color primaryBlue = Color(0xFF3B82F6);
    final userAvatarUrl = widget.currentUser?.photoURL;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl) : null,
          child: userAvatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_replyingToCommentId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Chip(
                    label: Text('Membalas @${_replyingToUserEmail ?? ''}', style: GoogleFonts.lato(color: Colors.blue.shade800)),
                    onDeleted: _cancelReply,
                    backgroundColor: Colors.blue.shade50,
                    deleteIconColor: Colors.blue.shade700,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              TextField(
                focusNode: _commentFocusNode,
                controller: _commentController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Tuliskan pemikiran Anda...',
                  border: InputBorder.none,
                ),
              ),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _postComment,
                  child: Text('Kirim', style: GoogleFonts.lato(color: primaryBlue, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
