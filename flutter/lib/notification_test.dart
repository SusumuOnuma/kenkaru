import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  String? _token;
  String _message = '通知待ち...';

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    // debugPrint('[NotificationTestWidget] _initFCM start');
    // Firebase初期化（main.dart側で未初期化の場合も考慮）
    try {
      await Firebase.initializeApp();
      // debugPrint('[NotificationTestWidget] Firebase initialized');
    } catch (e) {
      // debugPrint('[NotificationTestWidget] Firebase already initialized or error: $e');
    }

    // iOS/Android両対応で通知許可を明示的にリクエスト
    await _requestNotificationPermission();

    // FCMトークン取得
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
      debugPrint('[NotificationTestWidget] FCM token: $token');
    } catch (e) {
      debugPrint('[NotificationTestWidget] FCM token error: $e');
    }
    if (!mounted) return; // async gap対策
    setState(() {
      _token = token;
    });

    // トークン更新リスナー
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('[NotificationTestWidget] FCM token refreshed: $newToken');
      setState(() {
        _token = newToken;
      });
    });

    // フォアグラウンド通知リスナー
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          '[NotificationTestWidget] Foreground message: ${message.messageId}, data: ${message.data}, notification: ${message.notification}');
      setState(() {
        _message = 'フォアグラウンド通知: '
            '${message.notification?.title ?? 'タイトルなし'} - '
            '${message.notification?.body ?? '本文なし'}';
      });
    });
    debugPrint('[NotificationTestWidget] _initFCM end');
  }

  Future<void> _requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    // iOS: 許可ダイアログが出ない場合はUNUserNotificationCenterも明示的にリクエスト
    if (!mounted) return; // async gap対策（await後にcontextを使う前に必ずチェック）
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      try {
        await messaging.getNotificationSettings();
      } catch (e) {
        // debugPrint('[NotificationTestWidget] iOS notification settings error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('FCM Token: \n${_token ?? '取得中...'}'),
        SizedBox(height: 20),
        Text('受信メッセージ: $_message'),
      ],
    );
  }
}

// バックグラウンドメッセージハンドラ（トップレベル関数）
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('バックグラウンドでメッセージを受信しました: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(NotificationTestApp());
}

class NotificationTestApp extends StatefulWidget {
  const NotificationTestApp({super.key});

  @override
  State<NotificationTestApp> createState() => _NotificationTestAppState();
}

class _NotificationTestAppState extends State<NotificationTestApp> {
  String? _token;
  String _message = '通知待ち...';

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  void _initFCM() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    String? token = await FirebaseMessaging.instance.getToken();
    if (!mounted) return;
    setState(() {
      _token = token;
    });
    debugPrint('FCM Token: $_token');
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (!mounted) return;
      setState(() {
        _token = newToken;
      });
      debugPrint('FCM Token refreshed: $newToken');
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      debugPrint('フォアグラウンドでメッセージを受信しました: ${message.messageId}');
      debugPrint('メッセージデータ: ${message.data}');
      if (message.notification != null) {
        debugPrint('メッセージ通知タイトル: ${message.notification!.title}');
        debugPrint('メッセージ通知本文: ${message.notification!.body}');
      }
      setState(() {
        _message =
            'フォアグラウンド通知: ${message.notification?.title ?? 'タイトルなし'} - ${message.notification?.body ?? '本文なし'}';
      });
    });
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('アプリが終了状態から通知で開かれました: ${message.messageId}');
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('アプリがバックグラウンドから通知で開かれました: ${message.messageId}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FCM通知テスト'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "ケンカル\n配信テスト画面",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 32),
              Text('FCM Token: ${_token ?? ''}'),
              SizedBox(height: 20),
              Text('受信メッセージ: $_message'),
            ],
          ),
        ),
      ),
    );
  }
}
