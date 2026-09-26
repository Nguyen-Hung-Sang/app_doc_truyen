import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/screens/welcome_screen.dart';

// Khuyên dùng: Sử dụng file này nếu bạn đã chạy `flutterfire configure`
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Làm trong suốt thanh trạng thái (Status Bar) hệ thống
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Icon tối cho nền sáng
      statusBarBrightness: Brightness.light, // Dành cho iOS
    ),
  );

  try {
    // Cách 1: Khuyên dùng cho đa nền tảng (Android, iOS, Web)
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );

    // Cách 2: Cấu hình trực tiếp thủ công
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAXvfHxhiYoCObt_ExcwioFFU28_vIBxq0",
        appId: "1:215526392973:android:eb645f9ca868fd54a10ec4",
        messagingSenderId: "215526392973",
        projectId: "giai-tri-tong-hop-fcee6",
        storageBucket: "giai-tri-tong-hop-fcee6.firebasestorage.app",
      ),
    );
    debugPrint("🔥 Kết nối Firebase thành công!");
  } catch (e) {
    debugPrint("⚠️ Lỗi khởi tạo Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Đọc Truyện',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
