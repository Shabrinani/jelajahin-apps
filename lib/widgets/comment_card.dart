import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentCard extends StatelessWidget {
  final String noteId;
  final QueryDocumentSnapshot comment;
  final List<QueryDocumentSnapshot> replies;
  final Function(String commentId, String userEmail) onReply;

  const CommentCard({
    super.key,
    required this.noteId,
    required this.comment,
    required this.replies,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final data = comment.data() as Map<String, dynamic>;
    final userAvatar = data['userAvatar'] ?? 'https://via.placeholder.com/50';
    final userName = data['userName'] ?? 'Anonim';
    final userEmail = data['userEmail'] ?? 'anonim';
    final text = data['text'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Comment
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(userAvatar),
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(userName, style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(
                        '· ${timeago.format(timestamp, locale: 'id')}',
                        style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(text, style: GoogleFonts.lato(fontSize: 15)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => onReply(comment.id, userEmail),
                    child: Text(
                      'Balas',
                      style: GoogleFonts.lato(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Replies Section
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 52.0, top: 16),
            child: Column(
              children: replies.map((reply) {
                final replyData = reply.data() as Map<String, dynamic>;
                final replyAvatar = replyData['userAvatar'] ?? 'https://via.placeholder.com/50';
                final replyName = replyData['userName'] ?? 'Anonim';
                final replyText = replyData['text'] ?? '';
                final replyTimestamp = (replyData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(replyAvatar),
                        radius: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(replyName, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  '· ${timeago.format(replyTimestamp, locale: 'id')}',
                                  style: GoogleFonts.lato(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(replyText, style: GoogleFonts.lato(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
