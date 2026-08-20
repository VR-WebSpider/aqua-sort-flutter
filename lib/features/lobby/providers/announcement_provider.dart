import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? actionLabel;
  final String? actionPath;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.actionLabel,
    this.actionPath,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      actionLabel: json['action_label'] as String?,
      actionPath: json['action_path'] as String?,
    );
  }
}

final announcementProvider = FutureProvider<List<Announcement>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('announcements')
        .where('is_active', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Announcement.fromJson(data);
    }).toList();
  } catch (e) {
    return [];
  }
});
