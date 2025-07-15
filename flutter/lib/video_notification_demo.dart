import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:video_player/video_player.dart';
import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase('http://127.0.0.1:8090');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(VideoNotificationDemoApp());
}

class VideoNotificationDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Notification Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: VideoNotificationHomeScreen(),
    );
  }
}

class VideoNotificationHomeScreen extends StatefulWidget {
  @override
  State<VideoNotificationHomeScreen> createState() =>
      _VideoNotificationHomeScreenState();
}

class _VideoNotificationHomeScreenState
    extends State<VideoNotificationHomeScreen> {
  String? _token;
  String _message = '通知待ち...';
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _initFCM();
    // デモ用: ログイン＆通知登録
    _loginAndScheduleNotification();
  }

  Future<void> _initFCM() async {
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    _token = await FirebaseMessaging.instance.getToken();
    setState(() {});
    // フォアグラウンド通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.containsKey('video_url')) {
        final videoUrl = message.data['video_url'];
        setState(() {
          _message = '動画通知を受信: $videoUrl';
          _videoUrl = videoUrl;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoUrl: videoUrl)),
        );
      }
    });
    // 通知クリック時
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('video_url')) {
        final videoUrl = message.data['video_url'];
        setState(() {
          _message = '動画通知を開いた: $videoUrl';
          _videoUrl = videoUrl;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoUrl: videoUrl)),
        );
      }
    });
  }

  Future<void> _loginAndScheduleNotification() async {
    // 1. PocketBaseログイン
    await pb
        .collection('users')
        .authWithPassword('test@example.com', '1234567890');
    // 2. ファイルトークン取得
    final fileToken = await pb.files.getToken();
    // 3. 動画レコード取得
    final record = await pb.collection('videos').getOne('m32x53yhl908bv0');
    // 4. ProtectedファイルURL生成
    final videoUrl = pb.files
        .getURL(record, record.getStringValue('file'), token: fileToken);
    // 5. notificationsに1分後の通知を追加
    final now = DateTime.now();
    final scheduledAt = now.add(Duration(minutes: 1));
    final userId = pb.authStore.model.id;
    await pb.collection('notifications').create({
      'user': userId,
      'title': '新着動画',
      'body': '動画を再生してみましょう',
      'video_url': videoUrl,
      'scheduled_at': scheduledAt.toIso8601String(),
      'sent': false,
      'read': false,
    });
    setState(() {
      _message = '1分後に動画通知をスケジュールしました';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Notification Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('FCM Token: ${_token ?? '取得中...'}'),
            SizedBox(height: 20),
            Text('受信メッセージ: $_message'),
            if (_videoUrl != null) ...[
              SizedBox(height: 20),
              Text('動画URL: $_videoUrl'),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // バックグラウンドでの通知受信時の処理（必要に応じて実装）
}

class VideoPlayerScreen extends StatelessWidget {
  final String videoUrl;
  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Player')),
      body: Center(child: VideoPlayerWidget(videoUrl: videoUrl)),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : CircularProgressIndicator();
  }
}
