enum ServerStatus { active, slow, maintenance }

enum StoryType { manga, novel, all } // Truyện tranh, Truyện chữ, Tất cả

class StoryServer {
  final String id;
  final String name; // Tên nguồn (VD: NetTruyen)
  final String baseUrl; // Link web gốc (VD: https://nettruyen.com)
  final StoryType type; // Loại truyện
  final ServerStatus status; // Trạng thái kết nối
  final bool isVIP; // Nguồn tốc độ cao / Không quảng cáo

  StoryServer({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.type,
    this.status = ServerStatus.active,
    this.isVIP = false,
  });
}
