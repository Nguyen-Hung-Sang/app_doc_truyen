import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';

class ServerDiamondVipSource extends MangaSource {
  @override
  String get id => 'server_diamond_vip';

  @override
  String get name => 'vi-hentai';

  @override
  String get defaultBaseUrl => 'https://vi-hentai.pro/tac-gia/neoniez#!';

  @override
  SourceType get type => SourceType.all;

  @override
  SourceStatus get status => SourceStatus.stable;

  @override
  String? get tag => 'server diamond';

  @override
  List<String> get requiredRoles => ['admin', 'vip'];

  @override
  bool isUrlAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      // Chấp nhận tất cả tên miền phụ / domain chuyển hướng của vi-hentai (.pro, .moe, ...)
      if (host.contains('vi-hentai') ||
          host.contains('hentai.moe') ||
          host.contains('hentai.pro')) {
        return true;
      }
    }
    return super.isUrlAllowed(url);
  }

  @override
  String get adBlockScript => '''
    (function() {
      // 1. Chặn mở tab mới ngoài ý muốn khi click quảng cáo
      window.open = function() { return null; };

      // 2. CSS ẩn các banner cá cược xác định
      const style = document.createElement('style');
      style.innerHTML = `
        a[href*="vsbet"], a[href*="9922"], a[href*="au888"], a[href*="locphat"], 
        a[href*="hi88"], a[href*="mb66"], a[href*="xx88"], a[href*="v9bet"], 
        a[href*="shbet"], a[href*="hitclub"], a[href*="fun88"], a[href*="vebo"], 
        a[href*="u888"], a[href*="bec88"], a[href*="mm88"], a[href*="b52"], 
        a[href*="j88"], a[href*="f168"], a[href*="hay.win"], a[href*="tiger"], 
        a[href*="78win"], a[href*="c168"], a[href*="new68"], a[href*="sunwin"], 
        a[href*="kubet"], a[href*="red88"], a[href*="debet"], a[href*="zbet"],
        iframe[src*="6789x"], img[src*="vsbet"], img[src*="hi88"] {
          display: none !important;
        }
      `;
      (document.head || document.documentElement).appendChild(style);

      // 3. Quét dọn liên kết cá cược rác (GIỮ LẠI CỬA SỔ XÁC NHẬN / CÂU HỎI CỦA TRANG)
      function sweepAds() {
        document.querySelectorAll('a[target="_blank"]').forEach(a => {
          const href = (a.getAttribute('href') || '').toLowerCase();
          if (!href.includes('vi-hentai') && !href.includes('hentai') && !href.startsWith('/') && !href.startsWith('#')) {
            a.removeAttribute('target');
          }
        });

        const badKeywords = [
          'vsbet', '9922', 'au888', 'locphat', 'hi88', 'mb66', 'xx88', 'v9bet', 
          'shbet', 'hitclub', 'fun88', 'vebo', 'u888', 'bec88', 'mm88', 'b52', 
          'j88', 'f168', 'hay.win', 'tiger', '6789x', 'bong da', 'bóng đá', 
          'truc tiep', 'tường thuật', 'cá cược', 'tructiepbongda', 'hitclubs',
          '78win', 'c168', 'new68', 'kubet', 'sunwin', 'red88', 'debet', 'zbet'
        ];

        document.querySelectorAll('a, span, li, button, div').forEach(el => {
          // Bỏ qua không ẩn nếu phần tử thuộc cửa sổ câu hỏi / xác minh / modal / popup của trang
          const isVerificationElement = el.closest('.modal, .popup, .dialog, #modal, #popup, [class*="verify"], [id*="verify"], [class*="question"], [id*="question"], [class*="confirm"], [id*="confirm"], [class*="age"], [id*="age"], [class*="box"], [id*="box"]') != null;
          
          if (isVerificationElement) {
            return;
          }

          const href = (el.getAttribute('href') || '').toLowerCase();
          const text = (el.textContent || '').trim().toLowerCase();

          const isBadHref = badKeywords.some(kw => href.includes(kw));
          const isBadText = badKeywords.some(kw => text === kw || (text.includes(kw) && text.length < 50));

          if (isBadHref || isBadText) {
            if ((text.includes('vi-hentai') || text.includes('hentai')) && !isBadHref) return;
            el.style.setProperty('display', 'none', 'important');
          }
        });
      }

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
