enum StoryType { manga, novel, all }

enum ServerStatus { active, slow, maintenance }

class StoryServer {
  final String id;
  final String name;
  final String baseUrl;
  final StoryType type;
  final ServerStatus status;
  final bool isVIP;

  const StoryServer({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.type,
    required this.status,
    this.isVIP = false,
  });

  // Chuyển đổi dữ liệu JSON từ API (nếu có)
  factory StoryServer.fromJson(Map<String, dynamic> json) {
    return StoryServer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      type: StoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StoryType.manga,
      ),
      status: ServerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ServerStatus.active,
      ),
      isVIP: json['isVIP'] as bool? ?? false,
    );
  }

  // Chuyển đối tượng thành Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'type': type.name,
      'status': status.name,
      'isVIP': isVIP,
    };
  }
}
