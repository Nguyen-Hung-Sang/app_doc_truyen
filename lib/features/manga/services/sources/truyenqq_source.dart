import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';

class TruyenQQSource extends MangaSource {
  @override
  String get id => 'truyenqq';

  @override
  String get name => 'Nguồn TruyenQQ';

  @override
  String get defaultBaseUrl => 'https://truyenqqko.com/';

  @override
  SourceType get type => SourceType.manga;

  @override
  SourceStatus get status => SourceStatus.stable;

  @override
  String? get tag => 'Nhanh & Ổn định';

  @override
  String get adBlockScript => '''
    (function() {
      if (window.__truyenqqInjected) return;
      window.__truyenqqInjected = true;

      // 1. Sửa lỗi device is not defined trong file main.js gốc của web
      if (typeof window.device === 'undefined') {
        var trueFn = function() { return true; };
        var falseFn = function() { return false; };
        var deviceMock = {
          mobile: trueFn, android: trueFn, portrait: trueFn,
          tablet: falseFn, desktop: falseFn, ios: falseFn,
          type: 'mobile', orientation: 'portrait'
        };
        try {
          window.device = new Proxy(deviceMock, {
            get: function(target, prop) { return prop in target ? target[prop] : falseFn; }
          });
        } catch(e) { window.device = deviceMock; }
      }

      // 2. Chặn tự động mở tab popup quảng cáo
      try {
        window.open = function(url) {
          if (url && (url.indexOf('login') !== -1 || url.indexOf('auth') !== -1 || url.indexOf('facebook') !== -1 || url.indexOf('google') !== -1)) {
            window.location.href = url;
            return null;
          }
          return { focus: function(){}, blur: function(){}, close: function(){}, closed: false, location: { href: '' } };
        };
      } catch(e) {}

      // 3. Quét và xóa bỏ các popup quảng cáo nổi (Yo88, Rikvip, Hũ Nổ, Banner...)
      function removeAdOverlays() {
        var elements = document.querySelectorAll('div, iframe, a');
        for (var i = 0; i < elements.length; i++) {
          var el = elements[i];

          // BỎ QUA HOÀN TOÀN các phần tử thuộc Form Đăng Nhập / Đăng Ký
          if (el.closest('#login_modal, #register_modal, .modal, form') || 
              el.querySelector('form, input, button[type="submit"]')) {
            continue;
          }

          // Xóa iframe quảng cáo bên ngoài
          if (el.tagName === 'IFRAME') {
            var src = (el.src || '').toLowerCase();
            if (src.indexOf('truyenqq') === -1 && src.indexOf('google') === -1) {
              el.remove();
              continue;
            }
          }

          // Xóa quảng cáo game bài / nổ hũ theo từ khóa
          var html = (el.innerHTML || '').toLowerCase();
          var href = (el.href || '').toLowerCase();
          if (href.indexOf('rikvip') !== -1 || href.indexOf('yo88') !== -1 || href.indexOf('bet') !== -1 || 
              html.indexOf('hũ nổ') !== -1 || html.indexOf('rikvip') !== -1 || html.indexOf('yo88') !== -1) {
            var box = el.closest('div[style*="position"], div[class*="popup"], div[class*="ad"]') || el;
            box.remove();
            continue;
          }

          // Xóa các khung lớp phủ tàng hình/nổi đè trên màn hình
          var style = window.getComputedStyle(el);
          var zIndex = parseInt(style.zIndex, 10);
          if ((style.position === 'fixed' || style.position === 'absolute') && zIndex > 99) {
            if (!el.closest('header, #main_menu, .header, .navbar')) {
              if (el.querySelector('img') && !el.querySelector('input')) {
                el.remove();
              }
            }
          }
        }
      }

      removeAdOverlays();
      setInterval(removeAdOverlays, 600);

      // 4. CSS Ẩn Banner Quảng Cáo & Đảm Bảo Khung Đăng Nhập Hoạt Động
      if (!document.getElementById('app-truyenqq-adblock')) {
        var style = document.createElement('style');
        style.id = 'app-truyenqq-adblock';
        style.innerHTML = `
          #ad_mb, .ad_container, .ads_banner, .ad-content, .ads-responsive,
          div[class*="ad_"], div[id*="ad_"], div[class*="ads"], div[id*="ads"],
          a[href*="rikvip"], a[href*="yo88"] {
            display: none !important;
            pointer-events: none !important;
          }
          header, .header, #main_menu, .navbar,
          .modal, .modal-dialog, .modal-content, .modal-backdrop,
          #login_modal, #register_modal,
          form, input, button {
            pointer-events: auto !important;
          }
          .modal.show, .modal.in, #login_modal[style*="display"], #register_modal[style*="display"] {
            opacity: 1 !important;
            z-index: 9999999 !important;
          }
        `;
        (document.head || document.documentElement).appendChild(style);
      }
    })();
  ''';

  @override
  Future<List<dynamic>> fetchHomeList() async => [];

  @override
  Future<dynamic> fetchMangaDetail(String mangaUrl) async {}

  @override
  Future<List<dynamic>> searchManga(String keyword) async => [];
}
