import 'package:flutter/foundation.dart';

enum SourceType { manga, novel, all }

enum SourceStatus { stable, slow, maintenance }

abstract class MangaSource {
  String get id;
  String get name;

  /// Link mặc định dự phòng (nếu chưa tải được từ Firebase)
  String get defaultBaseUrl;

  /// Biến lưu link động được tải từ Firebase Firestore
  String customBaseUrl = '';

  /// Ưu tiên sử dụng link từ Firebase, nếu trống sẽ dùng link mặc định
  String get baseUrl =>
      customBaseUrl.isNotEmpty ? customBaseUrl : defaultBaseUrl;
  set baseUrl(String url) => customBaseUrl = url;

  SourceType get type;
  SourceStatus get status;
  String? get tag;

  List<String> get requiredRoles => [];

  bool hasAccess(String? userRole) {
    if (requiredRoles.isEmpty) return true;
    if (userRole == null || userRole.trim().isEmpty) return false;
    final role = userRole.trim().toLowerCase();
    if (role == 'admin') return true;
    return requiredRoles.map((r) => r.toLowerCase()).contains(role);
  }

  String get allowedHost {
    final uri = Uri.tryParse(baseUrl);
    return uri?.host.replaceAll('www.', '').toLowerCase() ?? '';
  }

  String get adBlockScript => '''
    (function() {
      window.open = function() { return null; };
    })();
  ''';

  /// Kiểm tra liên kết hợp lệ (Tự động chấp nhận khi Server đổi đuôi tên miền & Google Auth)
  bool isUrlAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final targetHost = uri.host.replaceAll('www.', '').toLowerCase();

    // 1. URL nội bộ / blank
    if (targetHost.isEmpty) return true;

    // 2. Google OAuth Login
    if (targetHost.contains('google.com') ||
        targetHost.contains('googleusercontent.com')) {
      return true;
    }

    // 3. Kiểm tra domain thuộc Server
    if (allowedHost.isNotEmpty) {
      // Khớp chính xác hoặc chứa tên miền gốc
      if (targetHost.contains(allowedHost) ||
          allowedHost.contains(targetHost)) {
        return true;
      }

      // Tách lấy tên thương hiệu chính (Ví dụ: 'damconuong.uno' -> 'damconuong')
      // Giúp chấp nhận mọi tên miền phụ/mới của Server đó (.name, .org, .net...)
      final hostParts = allowedHost.split('.');
      if (hostParts.length >= 2) {
        final mainDomain = hostParts[hostParts.length - 2];
        if (mainDomain.length >= 3 && targetHost.contains(mainDomain)) {
          return true;
        }
      }
    }

    return false;
  }

  Future<List<dynamic>> fetchHomeList();
  Future<dynamic> fetchMangaDetail(String mangaUrl);
  Future<List<dynamic>> searchManga(String keyword);
}
