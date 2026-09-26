import '../../models/manga_source_model.dart';

class BlogTruyenVipSource extends MangaSource {
  @override
  String get id => 'blogtruyen_vip';

  @override
  String get name => 'Vinahentai';

  @override
  String get defaultBaseUrl => 'https://vinahentai.click/';

  @override
  SourceType get type => SourceType.manga;

  @override
  SourceStatus get status => SourceStatus.stable;

  @override
  String? get tag => 'Vina Hentai';

  // CHỈ VIP VÀ ADMIN MỚI XEM ĐƯỢC
  @override
  List<String> get requiredRoles => ['vip', 'admin'];

  // Script JS chỉ ẩn duy nhất phần "LIÊN KẾT THAM KHẢO"
  @override
  String get adBlockScript => '''
    (function() {
      function removeLienKetThamKhao() {
        // Tìm tất cả các thẻ chứa chữ "LIÊN KẾT THAM KHẢO"
        const elements = document.querySelectorAll('*');
        elements.forEach(el => {
          if (el.children.length === 0 && el.textContent && el.textContent.trim().toUpperCase() === 'LIÊN KẾT THAM KHẢO') {
            // Ẩn khung chứa trực tiếp của tiêu đề này
            let parent = el.parentElement;
            if (parent) {
              parent.style.display = 'none';
            }
          }
        });
      }

      // Thực thi khi tải trang xong
      removeLienKetThamKhao();
      setTimeout(removeLienKetThamKhao, 1000);
      setTimeout(removeLienKetThamKhao, 2500);
    })();
  ''';

  @override
  Future<List<dynamic>> fetchHomeList() async => [];

  @override
  Future<dynamic> fetchMangaDetail(String mangaUrl) async => null;

  @override
  Future<List<dynamic>> searchManga(String keyword) async => [];
}
