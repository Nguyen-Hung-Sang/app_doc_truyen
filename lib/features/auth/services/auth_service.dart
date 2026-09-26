import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy thông tin User hiện tại từ FirebaseAuth
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream lắng nghe UserModel thời gian thực (Đã sửa lỗi treo Stream bằng StreamController)
  Stream<UserModel?> get userDataStream {
    late StreamController<UserModel?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot>? docSub;

    controller = StreamController<UserModel?>.broadcast(
      onListen: () {
        authSub = _auth.authStateChanges().listen((user) {
          docSub?.cancel(); // Hủy lắng nghe user cũ khi có trạng thái auth mới

          if (user == null) {
            controller.add(null);
          } else {
            docSub = _firestore
                .collection('users')
                .doc(user.uid)
                .snapshots()
                .listen((doc) {
                  if (doc.exists && doc.data() != null) {
                    controller.add(
                      UserModel.fromMap(doc.data() as Map<String, dynamic>),
                    );
                  } else {
                    controller.add(null);
                  }
                }, onError: (error) => controller.addError(error));
          }
        }, onError: (error) => controller.addError(error));
      },
      onCancel: () {
        docSub?.cancel();
        authSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 1. Đăng ký tài khoản
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String gender,
  }) async {
    User? createdUser;
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      createdUser = result.user;

      if (createdUser != null) {
        await createdUser.updateDisplayName(fullName.trim());

        UserModel newUser = UserModel(
          uid: createdUser.uid,
          fullName: fullName.trim(),
          gender: gender,
          email: email.trim(),
          role: 'user', // Mặc định role là user
          createdAt: DateTime.now(),
        );

        // Lưu thông tin vào Firestore
        await _firestore
            .collection('users')
            .doc(createdUser.uid)
            .set(newUser.toMap());
      }
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      if (createdUser != null && e.code != 'email-already-in-use') {
        await createdUser.delete().catchError((_) {});
      }
      return _handleAuthException(e);
    } catch (e) {
      if (createdUser != null) {
        await createdUser.delete().catchError((_) {});
      }
      return 'Lỗi hệ thống khi tạo tài khoản: ${e.toString()}';
    }
  }

  // 2. Đăng nhập
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'Đã xảy ra lỗi hệ thống: ${e.toString()}';
    }
  }

  // 3. Quên mật khẩu (Gửi email đặt lại mật khẩu)
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'Không thể gửi email đặt lại mật khẩu: ${e.toString()}';
    }
  }

  // 4. Lấy dữ liệu UserModel từ Firestore (Snapshot 1 lần)
  Future<UserModel?> getUserData() async {
    try {
      if (currentUser == null) return null;
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 5. Cập nhật thông tin Profile người dùng hiện tại
  Future<String?> updateUserData(Map<String, dynamic> data) async {
    try {
      if (currentUser == null) return 'Chưa đăng nhập tài khoản.';

      // Cập nhật dữ liệu Firestore
      await _firestore.collection('users').doc(currentUser!.uid).update(data);

      // Đồng bộ Display Name với Firebase Auth
      if (data.containsKey('fullName') && data['fullName'] != null) {
        await currentUser!.updateDisplayName(data['fullName']);
      }

      // Đồng bộ Email với Firebase Auth (nếu có đổi email)
      if (data.containsKey('email') &&
          data['email'] != null &&
          data['email'] != currentUser!.email) {
        await currentUser!.verifyBeforeUpdateEmail(data['email']);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'Cập nhật thông tin thất bại: ${e.toString()}';
    }
  }

  // 6. Đổi mật khẩu cho người dùng hiện tại
  Future<String?> changePassword({required String newPassword}) async {
    try {
      if (currentUser == null) return 'Chưa đăng nhập tài khoản.';
      await currentUser!.updatePassword(newPassword.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'Đổi mật khẩu thất bại: ${e.toString()}';
    }
  }

  // 7. Xác thực lại mật khẩu cũ (Dùng khi đổi mật khẩu bị yêu cầu đăng nhập lại)
  Future<String?> reauthenticate({required String currentPassword}) async {
    try {
      if (currentUser == null || currentUser!.email == null) {
        return 'Chưa đăng nhập.';
      }
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword.trim(),
      );
      await currentUser!.reauthenticateWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'Xác thực thất bại: ${e.toString()}';
    }
  }

  // --- CÁC HÀM DÀNH CHO QUẢN TRỊ VIÊN (ADMIN) ---

  // 8. Stream danh sách toàn bộ User cho Admin
  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.exists && doc.data().isNotEmpty)
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  // 9. Admin cập nhật thông tin/Role của một User bất kỳ
  Future<String?> updateUserByAdmin(
    String targetUid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(targetUid).update(data);
      return null;
    } catch (e) {
      return 'Lỗi cập nhật người dùng: ${e.toString()}';
    }
  }

  // 10. Admin xóa tài liệu User khỏi Firestore
  Future<String?> deleteUserByAdmin(String targetUid) async {
    try {
      await _firestore.collection('users').doc(targetUid).delete();
      return null;
    } catch (e) {
      return 'Lỗi xóa người dùng trên CSDL: ${e.toString()}';
    }
  }

  // 11. Tải lại trạng thái User hiện tại
  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  // 12. Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Hàm chuyển đổi các mã lỗi Firebase sang tiếng Việt
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email này chưa được đăng ký tài khoản.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập (email hoặc mật khẩu) không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng cho một tài khoản khác.';
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần tối thiểu 6 ký tự).';
      case 'user-disabled':
        return 'Tài khoản này đã bị khóa hoặc vô hiệu hóa.';
      case 'too-many-requests':
        return 'Thao tác quá nhiều lần. Vui lòng thử lại sau ít phút.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại Internet.';
      case 'requires-recent-login':
        return 'Thao tác yêu cầu xác thực mới. Vui lòng đăng nhập lại.';
      case 'channel-error':
        return 'Vui lòng điền đầy đủ các thông tin cần thiết.';
      default:
        return e.message ?? 'Đã xảy ra lỗi xác thực không xác định.';
    }
  }
}
