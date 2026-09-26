import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';

class NetTruyenSource extends MangaSource {
  @override
  String get id => 'nettruyen';

  @override
  String get name => 'Nguồn NetTruyen';

  @override
  String get defaultBaseUrl => 'https://nettruyen.gg/trang-chu';

  @override
  SourceType get type => SourceType.manga;

  @override
  SourceStatus get status => SourceStatus.stable;

  @override
  String? get tag => 'Nhanh';

  @override
  String get adBlockScript => '''
    (function() {
      if (window.__appInjected) return;
      window.__appInjected = true;

      // 1. DUMMY WINDOW.OPEN: Sửa đơ nút Menu (ba gạch) khi bấm
      try {
        var dummy = {
          focus: function(){}, blur: function(){}, close: function(){}, closed: false,
          location: { href: '', replace: function(){} },
          document: { write: function(){}, close: function(){} }
        };
        window.open = function() { return dummy; };
      } catch(e) {}

      // 2. CHẶN SENSOR: Vô hiệu hóa truy cập SensorManager (Chặn gigglegrowworrisome đào coin/ngốn CPU)
      var origAdd = window.addEventListener;
      window.addEventListener = function(type, listener, options) {
        if (type === 'deviceorientation' || type === 'devicemotion' || type === 'orientationchange') {
          return;
        }
        return origAdd.apply(this, arguments);
      };
      window.DeviceMotionEvent = undefined;
      window.DeviceOrientationEvent = undefined;
      window.onerror = function() { return true; };

      // 3. NÚT MŨI TÊN LÊN ĐẦU TRANG & NÚT MENU (Bắt sự kiện ưu tiên cao nhất)
      document.addEventListener('click', function(e) {
        // A. Nút mũi tên lên đầu trang (#back-to-top)
        var topBtn = e.target.closest('#back-to-top, .back-to-top, a[href*="top"], .gotop, #toTop');
        if (topBtn) {
          e.preventDefault();
          e.stopPropagation();
          window.scrollTo({ top: 0, behavior: 'smooth' });
          return;
        }

        // B. Nút Menu ba gạch (Dự phòng tự xổ menu nếu script của NetTruyen bị đơ)
        var menuBtn = e.target.closest('.navbar-toggle, [data-toggle="collapse"], .menu-trigger, .btn-navbar');
        if (menuBtn) {
          var targetId = menuBtn.getAttribute('data-target') || '#main-nav';
          var navMenu = document.querySelector(targetId) || document.querySelector('.navbar-collapse') || document.querySelector('#main-nav');
          if (navMenu) {
            var isHidden = getComputedStyle(navMenu).display === 'none' || !navMenu.classList.contains('in');
            navMenu.style.setProperty('display', isHidden ? 'block' : 'none', 'important');
            if (isHidden) navMenu.classList.add('in'); else navMenu.classList.remove('in');
          }
        }
      }, true);

      // 4. DỌN ĐỘC IFRAME & ẨN BANNER QUẢNG CÁO
      function removeBadIframes() {
        var iframes = document.getElementsByTagName('iframe');
        for (var i = iframes.length - 1; i >= 0; i--) {
          var src = iframes[i].src || '';
          if (src.indexOf('gigglegrow') !== -1 || src.indexOf('bn.js') !== -1 || src.indexOf('acscdn') !== -1) {
            if (iframes[i].parentNode) {
              iframes[i].parentNode.removeChild(iframes[i]);
            }
          }
        }
      }
      removeBadIframes();
      setInterval(removeBadIframes, 1500);

      if (!document.getElementById('app-adblock-style')) {
        var style = document.createElement('style');
        style.id = 'app-adblock-style';
        style.innerHTML = `
          .top-ads, .bottom-ads, .side-bar-ads, .cat-summary,
          iframe[src*="ad"], iframe[src*="acscdn"], iframe[src*="gigglegrow"] {
            display: none !important;
          }
          header, .navbar, .navbar-header, .navbar-toggle, #main-nav, #back-to-top, .back-to-top {
            pointer-events: auto !important;
            z-index: 99999 !important;
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
