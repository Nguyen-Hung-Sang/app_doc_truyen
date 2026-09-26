import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:app_doc_truyen/features/auth/screens/login_screen.dart';
import 'package:app_doc_truyen/features/auth/services/auth_service.dart';
import 'package:app_doc_truyen/features/manga/models/manga_source_model.dart';
import 'package:app_doc_truyen/features/manga/screens/manga_home_screen.dart';
import 'package:app_doc_truyen/features/manga/services/manga_source_manager.dart';
import 'package:app_doc_truyen/features/profile/screens/user_profile_screen.dart';

class ServerSelectionScreen extends StatefulWidget {
  const ServerSelectionScreen({super.key});

  @override
  State<ServerSelectionScreen> createState() => _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends State<ServerSelectionScreen> {
  final AuthService _authService = AuthService();

  List<MangaSource> _availableSources = [];
  MangaSource? _selectedSource;
  String _userRole = 'free';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndSources();
  }

  Future<void> _loadUserAndSources() async {
    // 1. Tải danh sách URL mới nhất từ Firestore collection 'Links Web'
    await MangaSourceManager.fetchUrlsFromFirestore();

    final user = _authService.currentUser;

    if (user != null) {
      try {
        // Truy vấn thông tin role từ Cloud Firestore theo UID người dùng
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final roleData = doc.data()!['role']?.toString().toLowerCase();
          if (roleData != null && roleData.isNotEmpty) {
            _userRole = roleData;
          }
        }
      } catch (e) {
        debugPrint('Lỗi lấy role từ Firestore: $e');
      }
    }

    // 2. Lọc danh sách các nguồn mà User này có quyền truy cập
    _availableSources = MangaSourceManager.allSources
        .where((source) => source.hasAccess(_userRole))
        .toList();

    // 3. Tự động chọn nguồn ổn định đầu tiên trong danh sách hợp lệ
    if (_availableSources.isNotEmpty) {
      _selectedSource = _availableSources.firstWhere(
        (s) => s.status == SourceStatus.stable,
        orElse: () => _availableSources.first,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(SourceStatus status) {
    switch (status) {
      case SourceStatus.stable:
        return const Color(0xFF10B981); // Xanh lá - Hoạt động tốt
      case SourceStatus.slow:
        return const Color(0xFFF59E0B); // Cam - Kết nối chậm
      case SourceStatus.maintenance:
        return const Color(0xFFEF4444); // Đỏ - Bảo trì
    }
  }

  String _getStatusLabel(SourceStatus status) {
    switch (status) {
      case SourceStatus.stable:
        return 'Ổn định';
      case SourceStatus.slow:
        return 'Chậm';
      case SourceStatus.maintenance:
        return 'Bảo trì';
    }
  }

  String _getTypeLabel(SourceType type) {
    switch (type) {
      case SourceType.manga:
        return 'Truyện tranh';
      case SourceType.novel:
        return 'Truyện chữ';
      case SourceType.all:
        return 'Tổng hợp';
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _confirmSelectServer() {
    if (_selectedSource == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (_selectedSource!.status == SourceStatus.maintenance) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Nguồn này đang bảo trì hoặc chặn IP, vui lòng chọn nguồn khác!',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            MangaHomeScreen(source: _selectedSource!, userRole: _userRole),
      ),
    );
  }

  // DIALOG CHO ADMIN CHỈNH SỬA LINK WEB KHI SẬP HOẶC ĐỔI TÊN MIỀN
  void _showEditUrlDialog(MangaSource source) {
    final urlController = TextEditingController(text: source.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sửa Link [${source.name}]',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập URL mới khi trang web bị sập hoặc đổi tên miền:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Link URL mới',
                hintText: 'https://example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.language),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isEmpty) return;

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang cập nhật link mới lên Firebase...'),
                ),
              );

              bool success =
                  await MangaSourceManager.updateSourceUrlInFirestore(
                    source.id,
                    newUrl,
                  );

              if (!mounted) return;

              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật Link Web thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lỗi cập nhật link. Vui lòng kiểm tra lại!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lưu Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    final user = _authService.currentUser;
    final displayName = user?.displayName;
    final email = user?.email;

    final avatarInitial = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()[0].toUpperCase()
        : (email != null && email.trim().isNotEmpty)
        ? email.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chọn Nguồn Đọc Truyện',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header người dùng
            _buildUserHeader(displayName, email, avatarInitial),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Thẻ nguồn đang chọn
            _buildSelectedSourceCard(),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Danh sách Server Web khả dụng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),

            // Danh sách các Nguồn đã được lọc theo Role
            Expanded(
              child: _availableSources.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy nguồn truyện phù hợp với tài khoản.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _availableSources.length,
                      itemBuilder: (context, index) {
                        final source = _availableSources[index];
                        final isSelected = _selectedSource?.id == source.id;
                        return _buildSourceCard(source, isSelected);
                      },
                    ),
            ),

            // Nút xác nhận
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(
    String? displayName,
    String? email,
    String avatarInitial,
  ) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserProfileScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                radius: 18,
                child: Text(
                  avatarInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName ?? email ?? 'Tài khoản Độc giả',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_userRole != 'free')
                      Text(
                        'Cấp độ: ${_userRole.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSourceCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.language_rounded,
              color: Color(0xFF2563EB),
              size: 36,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nguồn đang chọn:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedSource?.name ?? 'Chưa chọn',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(MangaSource source, bool isSelected) {
    final bool isAdmin = _userRole.toLowerCase() == 'admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? const Color(0xFFF0F6FF) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          setState(() => _selectedSource = source);
        },
        leading: Container(
          margin: const EdgeInsets.only(top: 6),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _getStatusColor(source.status),
            shape: BoxShape.circle,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                source.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (source.tag != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  source.tag!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getTypeLabel(source.type),
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getStatusLabel(source.status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(source.status),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
                tooltip: 'Sửa Link Web (Admin)',
                onPressed: () => _showEditUrlDialog(source),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _selectedSource == null ? null : _confirmSelectServer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Dùng Nguồn Này Để Đọc Truyện',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
