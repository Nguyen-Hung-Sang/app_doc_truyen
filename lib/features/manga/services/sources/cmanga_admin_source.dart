import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';

class CMangaAdminSource extends MangaSource {
  @override
  String get id => 'cmanga_admin';

  @override
  String get name => 'Damconuong ';

  @override
  String get defaultBaseUrl => 'https://damconuong.name/';

  @override
  SourceType get type => SourceType.all;

  @override
  SourceStatus get status => SourceStatus.stable;

  @override
  String? get tag => 'Damconuong';

  @override
  List<String> get requiredRoles => ['admin', 'vip'];

  @override
  bool isUrlAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      // Chấp nhận các domain gốc/chuyển hướng của Server CManga
      if (host.contains('damconuong') || host.contains('cmanga')) {
        return true;
      }
    }
    return super.isUrlAllowed(url);
  }

  @override
  String get adBlockScript => '''
    (function() {
      // 1. Chặn mở tab/cửa sổ mới
      window.open = function() { return null; };

      // 2. CSS ẩn nhanh các liên kết/banner chứa domain rác
      const style = document.createElement('style');
      style.innerHTML = `
        a[href*="vsbet"], a[href*="9922"], a[href*="au888"], a[href*="locphat"], 
        a[href*="hi88"], a[href*="mb66"], a[href*="xx88"], a[href*="v9bet"], 
        a[href*="shbet"], a[href*="hitclub"], a[href*="fun88"], a[href*="vebo"], 
        a[href*="u888"], a[href*="bec88"], a[href*="mm88"], a[href*="b52"], 
        a[href*="j88"], a[href*="f168"], a[href*="hay.win"], a[href*="tiger"], 
        a[href*="6789x"], iframe[src*="6789x"],
        img[src*="vsbet"], img[src*="9922"], img[src*="au888"], img[src*="locphat"], img[src*="6789x"] {
          display: none !important;
        }
      `;
      (document.head || document.documentElement).appendChild(style);

      // 3. Hàm quét dọn triệt để các nút Tag/Pill rác chân trang
      function sweepAds() {
        // Loại bỏ target="_blank"
        document.querySelectorAll('a[target="_blank"]').forEach(a => {
          a.removeAttribute('target');
        });

        // Danh sách từ khóa rác xuất hiện trên các nút/tag chân trang
        const badKeywords = [
          'vsbet', '9922', 'au888', 'locphat', 'hi88', 'mb66', 'xx88', 'v9bet', 
          'shbet', 'hitclub', 'fun88', 'vebo', 'u888', 'bec88', 'mm88', 'b52', 
          'j88', 'f168', 'hay.win', 'tiger', '6789x', 'bong da', 'bóng đá', 
          'truc tiep', 'trực tiếp', 'tuong thuat', 'tường thuật', 'hit club', 
          'adsdance', 'cá cược', 'tructiepbongda', 'jav', 'hitclubs'
        ];

        // Quét các thẻ tag link, span, li, button
        document.querySelectorAll('a, span, li, button, div').forEach(el => {
          const href = (el.getAttribute('href') || '').toLowerCase();
          const text = (el.textContent || '').trim().toLowerCase();

          const isBadHref = badKeywords.some(kw => href.includes(kw));
          // Kiểm tra chữ hiển thị trên nút (giới hạn độ dài < 60 để không ẩn nhầm văn bản dài)
          const isBadText = badKeywords.some(kw => text.includes(kw));

          if (isBadHref || (isBadText && text.length < 60)) {
            el.style.setProperty('display', 'none', 'important');
          }
        });
      }

      // 4. Lắng nghe & xóa liên tục khi trang load thêm dữ liệu
      sweepAds();
      const observer = new MutationObserver(sweepAds);
      observer.observe(document.body || document.documentElement, {
        childList: true,
        subtree: true
      });
    })();
  ''';

  @override
  Future<List<dynamic>> fetchHomeList() async => [];

  @override
  Future<dynamic> fetchMangaDetail(String mangaUrl) async => null;

  @override
  Future<List<dynamic>> searchManga(String keyword) async => [];
}
