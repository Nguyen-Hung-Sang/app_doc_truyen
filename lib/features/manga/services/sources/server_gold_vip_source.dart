import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';

class ServerGoldVipSource extends MangaSource {
  @override
  String get id => 'server_gold_vip';

  @override
  String get name => 'Sayhentai';

  @override
  String get defaultBaseUrl => 'https://sayhentai.cx/';

  @override
  SourceType get type => SourceType.all;

  @override
  SourceStatus get status => SourceStatus.stable;

  @override
  String? get tag => 'server gold';

  @override
  List<String> get requiredRoles => ['admin', 'vip'];

  @override
  bool isUrlAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host.contains('sayhentai')) {
        return true;
      }
    }
    return super.isUrlAllowed(url);
  }

  @override
  String get adBlockScript => '''
    (function() {
      // 1. Chặn mở tab mới & cửa sổ Pop-up / Pop-under
      window.open = function() { return null; };

      // Chặn nhúng iframe quảng cáo động
      const originalAppend = Element.prototype.appendChild;
      Element.prototype.appendChild = function(element) {
        if (element.tagName === 'IFRAME' && element.src) {
          const src = element.src.toLowerCase();
          if (!src.includes('sayhentai') && (src.includes('ads') || src.includes('doubleclick') || src.includes('6789x'))) {
            return null;
          }
        }
        return originalAppend.call(this, element);
      };

      // 2. CSS chèn ẩn tức thì các banner nổi & domain rác
      const style = document.createElement('style');
      style.innerHTML = `
        div[class*="float-ad"], div[class*="pop-ad"], div[id*="pop-ad"],
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

      // 3. Quét dọn cửa sổ nổi và khối liên kết đối tác rác
      function sweepAds() {
        document.querySelectorAll('a[target="_blank"]').forEach(a => {
          a.removeAttribute('target');
        });

        // 3.1. Tìm và ẩn sạch nguyên khối "LIÊN KẾT ĐỐI TÁC & CHUYÊN MỤC"
        document.querySelectorAll('h1, h2, h3, h4, h5, h6, div, p, span, strong').forEach(el => {
          const text = (el.textContent || '').trim().toLowerCase();
          if (text.includes('liên kết đối tác') || text.includes('đối tác & chuyên mục')) {
            let parent = el.parentElement;
            while (parent && parent.tagName !== 'BODY') {
              if (parent.querySelectorAll('a').length > 3) {
                parent.style.setProperty('display', 'none', 'important');
                break;
              }
              parent = parent.parentElement;
            }
          }
        });

        // 3.2. Danh sách từ khóa rác xuất hiện trong ảnh đối tác
        const badKeywords = [
          '78win', 'c168', 'new68', 'sao789', 'sumclub', 'i9bet', 'nohu', 'nổ hũ',
          'hitclub', 'f8bet', 'soi kèo', 'kèo nhà cái', 'sunwin', 'shbet', 'rr88',
          'w88', 'saoke', '789club', '789 club', 'qq88', 'fly88', 'gavangtv',
          'socolive', 'rakhoitv', 'man79', 'red88', 'cakhiatv', 'cakhia', 'qq68',
          'hb88', 'luck8', 'rikvip', 'vlxx', 'da88', 'tx88', 'lu88', 'bet88',
          'jun88', 'ww88', 'sv888', '8xbet', 'pg88', 'pg99', 'pg66', 'sun52',
          'mu88', '88clb', 'u888', 'vebo', 'qh88', 'vivu88', 'five88', 'may88',
          'sky88', 'tdtc', 'game bài', 'kubet', '33win', 'good88', 'debet',
          'zbet', 'one88', 'xoilac', 'sv368', 'alo789', 'ee88', 'cwin', 'abc8',
          'xoso68', 'ae888', 'vsbet', '9922', 'au888', 'locphat', 'hi88',
          'mb66', 'xx88', 'v9bet', 'bec88', 'mm88', 'b52', 'j88', 'f168',
          'hay.win', 'tiger', '6789x', 'bong da', 'bóng đá', 'truc tiep',
          'tường thuật', 'cá cược', 'tructiepbongda', 'sex hentai'
        ];

        // 3.3. Lọc ẩn các nút tag rác lẻ
        document.querySelectorAll('a, span, li, button, div').forEach(el => {
          const href = (el.getAttribute('href') || '').toLowerCase();
          const text = (el.textContent || '').trim().toLowerCase();

          const isBadHref = badKeywords.some(kw => href.includes(kw));
          const isBadText = badKeywords.some(kw => text === kw || (text.includes(kw) && text.length < 50));

          if (isBadHref || isBadText) {
            // Giữ lại nút tag chính chủ SayHentai
            if (text.includes('sayhentai') && !isBadHref) return;

            el.style.setProperty('display', 'none', 'important');
          }
        });

        // 3.4. Ẩn các cửa sổ nổi cố định (Floating Popup Overlays)
        document.querySelectorAll('div, section').forEach(el => {
          const style = window.getComputedStyle(el);
          if (style.position === 'fixed' || style.position === 'sticky') {
            const isNav = el.tagName === 'HEADER' || el.tagName === 'NAV' || 
                          el.id.toLowerCase().includes('nav') || el.id.toLowerCase().includes('header') ||
                          el.className.toLowerCase().includes('nav') || el.className.toLowerCase().includes('header');
            
            if (!isNav && (el.querySelector('iframe, img') || badKeywords.some(kw => el.innerHTML.toLowerCase().includes(kw)))) {
              el.style.setProperty('display', 'none', 'important');
            }
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
