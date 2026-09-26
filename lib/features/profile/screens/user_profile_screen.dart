import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.redAccent;
      case 'vip':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF2563EB);
    }
  }

  // --- CÁC CHỨC NĂNG QUẢN TRỊ ADMIN ---

  // 1. Sửa thông tin người dùng
  void _editUserDialog(String docId, Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(
      text: user['fullName'] ?? user['name'] ?? '',
    );
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    String selectedGender = user['gender'] ?? 'Nam';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa thông tin người dùng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            DropdownButtonFormField<String>(
              value: ['Nam', 'Nữ', 'Khác'].contains(selectedGender)
                  ? selectedGender
                  : 'Nam',
              items: [
                'Nam',
                'Nữ',
                'Khác',
              ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => selectedGender = val!,
              decoration: const InputDecoration(labelText: 'Giới tính'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .update({
                      'fullName': nameCtrl.text,
                      'email': emailCtrl.text,
                      'gender': selectedGender,
                    });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật thông tin thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi cập nhật: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // 2. Thay đổi Role người dùng
  void _changeRoleDialog(String docId, String currentRole) {
    String selectedRole = currentRole.toLowerCase();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thay đổi Role người dùng'),
        content: DropdownButtonFormField<String>(
          value: ['user', 'vip', 'admin'].contains(selectedRole)
              ? selectedRole
              : 'user',
          items: const [
            DropdownMenuItem(value: 'user', child: Text('User')),
            DropdownMenuItem(value: 'vip', child: Text('Vip')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (val) => selectedRole = val!,
          decoration: const InputDecoration(labelText: 'Chọn Role mới'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .update({'role': selectedRole});

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật Role thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi cập nhật Role: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  // 3. Xóa người dùng
  void _deleteUser(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa người dùng này khỏi CSDL?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(docId)
                    .delete();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa người dùng!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi xóa người dùng: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Người dùng chưa đăng nhập!')),
      );
    }

    // STREAM LẤY THÔNG TIN TÀI KHOẢN ĐANG LOGIN
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('Không tìm thấy thông tin trên Firestore.'),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        final String userName =
            userData['fullName'] ?? userData['name'] ?? 'Chưa đặt tên';
        final String userEmail =
            userData['email'] ?? currentUser.email ?? 'Chưa có email';
        final String userGender = userData['gender'] ?? 'Chưa cập nhật';
        final String currentUserRole = userData['role'] ?? 'user';
        final bool isAdmin = currentUserRole.toLowerCase() == 'admin';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Thông Tin Tài Khoản',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            elevation: 0.5,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD THÔNG TIN CÁ NHÂN TẢI ĐỘNG TỪ FIREBASE AUTH/FIRESTORE
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(
                              currentUserRole,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Role: $currentUserRole',
                            style: TextStyle(
                              color: _getRoleColor(currentUserRole),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 32),
                        ListTile(
                          leading: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF2563EB),
                          ),
                          title: const Text('Email'),
                          subtitle: Text(userEmail),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF2563EB),
                          ),
                          title: const Text('Giới tính'),
                          subtitle: Text(userGender),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // DANH SÁCH TẤT CẢ USER & CÁC CHỨC NĂNG ADMIN
                if (isAdmin) ...[
                  const Text(
                    'Chức Năng Quản Trị (Admin)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // STREAM LẤY TOÀN BỘ DANH SÁCH USER NẾU LÀ ADMIN
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Lỗi tải danh sách: ${snapshot.error}');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Text(
                          'Không có người dùng nào trong CSDL.',
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final itemData = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;

                          final String name =
                              itemData['fullName'] ??
                              itemData['name'] ??
                              'Chưa đặt tên';
                          final String email = itemData['email'] ?? 'No Email';
                          final String gender = itemData['gender'] ?? 'N/A';
                          final String role = itemData['role'] ?? 'user';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('$email | $gender | Role: $role'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _editUserDialog(docId, itemData),
                                    tooltip: 'Sửa thông tin',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.admin_panel_settings_outlined,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () =>
                                        _changeRoleDialog(docId, role),
                                    tooltip: 'Đổi Role',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteUser(docId),
                                    tooltip: 'Xóa người dùng',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
