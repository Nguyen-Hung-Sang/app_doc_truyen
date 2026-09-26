import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';

class MangaHomeScreen extends StatefulWidget {
  final MangaSource source;
  final String userRole;

  const MangaHomeScreen({
    super.key,
    required this.source,
    required this.userRole,
  });

  @override
  State<MangaHomeScreen> createState() => _MangaHomeScreenState();
}

class _MangaHomeScreenState extends State<MangaHomeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            // Thực thi script chặn banner/pop-up/redirect từ nguồn truyện
            _controller.runJavaScript(widget.source.adBlockScript);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Lỗi tải trang: ${error.description}');
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();

            // 1. Chặn các ứng dụng bên ngoài mở qua URL Scheme (intent://, market://)
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }

            // 2. NGOẠI LỆ: Cho phép điều hướng để Đăng nhập Google / OAuth
            if (url.contains('accounts.google.com') ||
                url.contains('googleusercontent.com')) {
              return NavigationDecision.navigate;
            }

            // 3. CHẶN ĐIỀU HƯỚNG: Chỉ cho phép vào các trang thuộc Domain của Server
            if (!widget.source.isUrlAllowed(request.url)) {
              debugPrint('Đã chặn chuyển hướng sang URL ngoài: ${request.url}');
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.source.baseUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Trở về chọn Server',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.source.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              tooltip: 'Trang trước',
              onPressed: () async {
                if (await _controller.canGoBack()) {
                  await _controller.goBack();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              tooltip: 'Trang sau',
              onPressed: () async {
                if (await _controller.canGoForward()) {
                  await _controller.goForward();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tải lại trang',
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
