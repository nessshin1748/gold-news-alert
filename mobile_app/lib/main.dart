import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:permission_handler/permission_handler.dart";
import "package:shared_preferences/shared_preferences.dart";
import "dart:io" show Platform;

// Global navigator key for navigation from background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler (must be top-level function)
@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showLocalNotification(message);
  print("Background message: ${message.messageId}");
}

// Show local notification (works in foreground/background)
Future<void> _showLocalNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    "gold_alerts",
    "Gold News Alerts",
    channelDescription: "Notifications for high/medium impact USD news affecting Gold",
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: "@mipmap/ic_launcher",
  );
  
  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
  
  await flutterLocalNotificationsPlugin.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    message.notification?.title ?? "Gold Alert",
    message.notification?.body ?? "New gold-relevant news",
    platformDetails,
    payload: jsonEncode(message.data),
  );
}

import "dart:convert";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Setup local notifications
  await _initLocalNotifications();
  
  // Request permissions
  await _requestPermissions();
  
  // Setup FCM
  await _setupFCM();
  
  runApp(const GoldNewsApp());
}

Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings(
    "@mipmap/ic_launcher",
  );
  
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      // Handle notification tap
      if (details.payload != null) {
        print("Notification tapped: ${details.payload}");
      }
    },
  );
  
  // Create notification channel for Android
  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      "gold_alerts",
      "Gold News Alerts",
      description: "Notifications for high/medium impact USD news affecting Gold",
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ));
  }
}

Future<void> _requestPermissions() async {
  // Request notification permissions
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }
  
  // Request Android 13+ notification permission
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print("Notification permission denied");
    }
  }
  
  // Request exact alarm permission for scheduled notifications (Android 12+)
  if (Platform.isAndroid) {
    await Permission.scheduleExactAlarm.request();
  }
}

Future<void> _setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Get FCM token
  String? token = await messaging.getToken();
  print("FCM Token: $token");
  
  // Subscribe to gold_alerts topic
  await messaging.subscribeToTopic("gold_alerts");
  print("Subscribed to gold_alerts topic");
  
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message: ${message.notification?.title}");
    _showLocalNotification(message);
  });
  
  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Handle notification tap when app is terminated
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print("App opened from terminated state: ${message.notification?.title}");
    }
  });
  
  // Handle token refresh
  messaging.onTokenRefresh.listen((newToken) {
    print("FCM Token refreshed: $newToken");
  });
}

class GoldNewsApp extends StatelessWidget {
  const GoldNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gold News Alert",
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fcmToken = "Loading...";
  bool _isSubscribed = false;
  List<Map<String, dynamic>> _notifications = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _listenForNotifications();
  }
  
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await FirebaseMessaging.instance.getToken();
    
    setState(() {
      _fcmToken = token ?? "Not available";
      _isSubscribed = true; // We subscribe in main()
      _notifications = (prefs.getStringList("notifications") ?? [])
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    });
  }
  
  void _listenForNotifications() {
    FirebaseMessaging.onMessage.listen((message) {
      final data = {
        "title": message.notification?.title ?? "",
        "body": message.notification?.body ?? "",
        "time": DateTime.now().toIso8601String(),
        "type": message.data["type"] ?? "unknown",
        ...message.data,
      };
      _saveNotification(data);
    });
  }
  
  Future<void> _saveNotification(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("notifications") ?? [];
    list.add(jsonEncode(data));
    // Keep last 50
    if (list.length > 50) list.removeRange(0, list.length - 50);
    await prefs.setStringList("notifications", list);
    _loadData();
  }
  
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("notifications");
    _loadData();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gold News Alert"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearHistory,
            tooltip: "Clear history",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSubscribed ? Icons.check_circle : Icons.cancel,
                          color: _isSubscribed ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSubscribed ? "Notifications Active" : "Notifications Inactive",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text("FCM Token:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    SelectableText(
                      _fcmToken,
                      style: const TextStyle(fontFamily: "monospace", fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final token = await FirebaseMessaging.instance.getToken();
                        if (token != null) {
                          await SharedPreferences.getInstance().then((p) => p.setString("fcm_token", token));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Token copied to clipboard")),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy Token"),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "How it works",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("• 📅 Daily Digest at 06:00 - Summary of today's high/medium USD news"),
                    const Text("• ⚡ Real-time alerts - When high/medium impact news is released"),
                    const Text("• 🎯 Filtered for Gold - Only news affecting XAU/USD"),
                    const Text("• 🔕 Quiet hours: 02:00-06:00 (no notifications)"),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notification History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Recent Alerts", style: Theme.of(context).textTheme.titleLarge),
                if (_notifications.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearHistory,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text("Clear"),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No alerts yet",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Alerts will appear here when high/medium impact USD news is released",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final time = DateTime.tryParse(n["time"] ?? "") ?? DateTime.now();
                        final type = n["type"] ?? "unknown";
                        final isBreaking = type == "breaking";
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isBreaking
                              ? Colors.red.shade50
                              : Colors.blue.shade50,
                          child: ListTile(
                            leading: Icon(
                              isBreaking ? Icons.flash_on : Icons.schedule,
                              color: isBreaking ? Colors.red : Colors.blue,
                            ),
                            title: Text(
                              n["title"] ?? "",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n["body"] ?? ""),
                                const SizedBox(height: 4),
                                Text(
                                  "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}  •  ${isBreaking ? "Breaking" : "Daily Digest"}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
