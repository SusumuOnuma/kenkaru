import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// main.dart等から呼び出せる通知テスト用ウィジェット
class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({Key? key}) : super(key: key);

  @override
  _NotificationTestWidgetState createState() => _NotificationTestWidgetState();
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
    debugPrint('[NotificationTestWidget] _initFCM start');
    // Firebase初期化（main.dart側で未初期化の場合も考慮）
    try {
      await Firebase.initializeApp();
      debugPrint('[NotificationTestWidget] Firebase initialized');
    } catch (e) {
      debugPrint('[NotificationTestWidget] Firebase already initialized or error: $e');
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
      debugPrint('[NotificationTestWidget] Foreground message: ${message.messageId}, data: ${message.data}, notification: ${message.notification}');
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
    debugPrint('[NotificationTestWidget] requestPermission start');
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[NotificationTestWidget] User granted permission: ${settings.authorizationStatus}');

    // iOS: 許可ダイアログが出ない場合はUNUserNotificationCenterも明示的にリクエスト
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      try {
        final plugin = await messaging.getNotificationSettings();
        debugPrint('[NotificationTestWidget] iOS notification settings: $plugin');
      } catch (e) {
        debugPrint('[NotificationTestWidget] iOS notification settings error: $e');
      }
    }
    debugPrint('[NotificationTestWidget] requestPermission end');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('FCM Token: \\n' + (_token ?? '取得中...')),
        SizedBox(height: 20),
        Text('受信メッセージ: $_message'),
      ],
    );
  }
}

// バックグラウンドメッセージハンドラ（トップレベル関数）
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('バックグラウンドでメッセージを受信しました: [32m${message.messageId}[0m');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(NotificationTestApp());
}

class NotificationTestApp extends StatefulWidget {
  @override
  _NotificationTestAppState createState() => _NotificationTestAppState();
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
    print('User granted permission: ${settings.authorizationStatus}');
    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      _token = token;
    });
    print('FCM Token: $_token');
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      setState(() {
        _token = newToken;
      });
      print('FCM Token refreshed: $newToken');
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('フォアグラウンドでメッセージを受信しました: ${message.messageId}');
      print('メッセージデータ: ${message.data}');
      if (message.notification != null) {
        print('メッセージ通知タイトル: ${message.notification!.title}');
        print('メッセージ通知本文: ${message.notification!.body}');
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
        print('アプリが終了状態から通知で開かれました: ${message.messageId}');
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('アプリがバックグラウンドから通知で開かれました: ${message.messageId}');
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
              // 既存の配信テスト画面テキスト
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
              // 通知テスト情報
              Text('FCM Token: $_token'),
              SizedBox(height: 20),
              Text('受信メッセージ: $_message'),
            ],
          ),
        ),
      ),
    );
  }
}
