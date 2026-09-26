import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';
import 'package:app_doc_truyen/features/manga/services/sources/nettruyen_source.dart';
import 'package:app_doc_truyen/features/manga/services/sources/truyenqq_source.dart';
import 'package:app_doc_truyen/features/manga/services/sources/blogtruyen_vip_source.dart';
import 'package:app_doc_truyen/features/manga/services/sources/cmanga_admin_source.dart';
import 'package:app_doc_truyen/features/manga/services/sources/server_gold_vip_source.dart';
import 'package:app_doc_truyen/features/manga/services/sources/server_diamond_vip_source.dart';

class MangaSourceManager {
  // Danh sách tất cả các nguồn khả dụng trong App
  static final List<MangaSource> allSources = [
    NetTruyenSource(), // Miễn phí
    TruyenQQSource(), // Miễn phí
    BlogTruyenVipSource(), // VIP & Admin
    CMangaAdminSource(), // VIP & Admin
    ServerGoldVipSource(), // VIP & Admin
    ServerDiamondVipSource(), // VIP & Admin
  ];

  // Lấy nguồn theo ID
  static MangaSource getSourceById(String id) {
    return allSources.firstWhere(
      (source) => source.id == id,
      orElse: () => NetTruyenSource(),
    );
  }

  // TẢI LINK ĐỘNG TỪ FIREBASE COLLECTION 'Links Web'
  static Future<void> fetchUrlsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Links Web')
          .get();

      // Ánh xạ tên Document ('Link 1', 'Link 2'...) sang ID của từng nguồn trong App
      final Map<String, String> docMapping = {
        'Link 1': 'nettruyen',
        'Link 2': 'truyenqq',
        'Link 3': 'blogtruyen_vip',
        'Link 4': 'cmanga_admin',
        'Link 5': 'server_gold_vip',
        'Link 6': 'server_diamond_vip',
      };

      for (var doc in snapshot.docs) {
        if (!doc.exists) continue;
        final data = doc.data();
        final String? linkUrl = data['LinkURL']?.toString().trim();

        if (linkUrl == null || linkUrl.isEmpty) continue;

        // Xác định ID nguồn cần cập nhật (chấp nhận cả 'Link 1' hoặc ID trực tiếp 'nettruyen')
        final String targetId = docMapping[doc.id] ?? doc.id;

        for (var source in allSources) {
          if (source.id == targetId || source.id == doc.id) {
            source.baseUrl = linkUrl;
            debugPrint('🌐 Cập nhật [${source.name}] -> $linkUrl');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi tải link từ Firebase Firestore: $e');
    }
  }
}
