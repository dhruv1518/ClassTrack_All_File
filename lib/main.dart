import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'login.dart';
import 'home_screen.dart';
import 'auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'todo_service.dart';
import 'calendar_service.dart';
import 'exam_planner_service.dart';

// ----------------------------------------------------------
// 📌 REQUIRED: FCM Background Message Handler
// ----------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// ----------------------------------------------------------
// 📌 Local Notifications Plugin
// ----------------------------------------------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notification settings
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ClassTrack',
            theme: themeProvider.themeData,
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 🚀 SPLASH SCREEN WITH FCM INIT + ANIMATIONS
// ----------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _particlesController;

  // Splash colors will be read from ThemeProvider in build()

  final int particleCount = 20;
  final Random random = Random();

  late List<Offset> particlePositions;
  late List<double> particleSizes;

  @override
  void initState() {
    super.initState();

    _initFCM(); // 🚀 Initialize Push Notifications

    // Logo Animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Particle animation
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    particlePositions = List.generate(
      particleCount,
      (index) => Offset(
        random.nextDouble() * 300 - 150,
        random.nextDouble() * 300 - 150,
      ),
    );

    particleSizes = List.generate(
      particleCount,
      (index) => random.nextDouble() * 4 + 2,
    );

    // After animation → check auth state and navigate
    Timer(const Duration(milliseconds: 3500), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Already logged in — fetch user data and go to HomeScreen
        final authService = AuthService();
        final userData = await authService.getUserData();
        if (userData != null && mounted) {
          ToDoService().setUser(user.uid);
          CalendarService().setUser(user.uid);
          ExamPlannerService().setUser(user.uid);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                name: userData['name'] ?? 'User',
                enrollment: userData['enrollment'] ?? 'N/A',
                email: userData['email'] ?? 'No email',
              ),
            ),
          );
          return;
        }
      }
      // Not logged in — go to Login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentLoginPage()),
        );
      }
    });
  }

  // ----------------------------------------------------
  // 🚀 FIREBASE CLOUD MESSAGING INITIALIZATION
  // ----------------------------------------------------
  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Ask permission
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get FCM token
    String? token = await messaging.getToken();

    // Save token to Firestore
    if (token != null) {
      await FirebaseFirestore.instance
          .collection("users_tokens")
          .doc(token)
          .set({"token": token, "timestamp": FieldValue.serverTimestamp()});
    }

    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? "New Message",
        message.notification?.body ?? "",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'classtrack_channel',
            'ClassTrack Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  // ----------------------------------------------------
  // ✅ FIX: Dispose all AnimationControllers (IMPORTANT)
  // ----------------------------------------------------
  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double logoSize = 180;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F3EF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF9F3EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _particlesController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ParticlesPainter(
                    particlePositions,
                    particleSizes,
                    _particlesController.value,
                    const Color(0xFF1B3C53),
                  ),
                  size: Size(logoSize * 3, logoSize * 3),
                );
              },
            ),

            // Centered Logo + App Name
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        'images/appphoto3.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "ClassTrack",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B3C53),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 🎨 PARTICLE PAINTER
// ----------------------------------------------------------------------
class _ParticlesPainter extends CustomPainter {
  final List<Offset> positions;
  final List<double> sizes;
  final double progress;
  final Color color;

  _ParticlesPainter(this.positions, this.sizes, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color.withOpacity(0.6);

    for (int i = 0; i < positions.length; i++) {
      double angle = 2 * pi * progress + i;
      double radius = 50 + i * 5;

      Offset offset =
          center +
          Offset(
            cos(angle) * radius + positions[i].dx,
            sin(angle) * radius + positions[i].dy,
          );

      canvas.drawCircle(offset, sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
