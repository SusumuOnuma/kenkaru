import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart'; // 不要なため削除
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _token;
  String? _status;
  // platformは不要になったので削除
  String? _videoUrl;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initFCMAndSendToken();
    _listenNotificationForVideo();
  }

  Future<void> _initFCMAndSendToken() async {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    setState(() {
      _token = fcmToken;
    });
    final pb = PocketBase(const String.fromEnvironment('POCKETBASE_URL',
        defaultValue: 'http://127.0.0.1:8090'));
    if (pb.authStore.isValid) {
      try {
        final record = await pb.collection('fcm_tokens').create(body: {
          'user': pb.authStore.record?.id, // null安全対応
          'token': fcmToken,
        });
        setState(() {
          _status = 'FCMトークン登録成功: ${record.id}'; // 補間へ
        });
      } catch (e) {
        setState(() {
          _status = 'FCMトークン登録失敗: $e';
        });
      }
    } else {
      setState(() {
        _status = 'PocketBase未認証です';
      });
    }
  }

  void _listenNotificationForVideo() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final videoUrl = data['video_url'] ?? message.notification?.body;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        setState(() {
          _videoUrl = videoUrl;
        });
        _initVideoPlayer(videoUrl);
      }
    });
  }

  Future<void> _initVideoPlayer(String url) async {
    _videoController?.dispose();
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(url)); // 非推奨API置換
    await _videoController!.initialize();
    setState(() {});
    _videoController!.play();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('FCM Token: \\${_token ?? "取得中..."}'),
              SizedBox(height: 16),
              // Platform表示は不要になったので削除
              Text(_status ?? 'FCMトークン送信待ち...'),
              SizedBox(height: 32),
              if (_videoUrl != null &&
                  _videoController != null &&
                  _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              if (_videoUrl != null &&
                  (_videoController == null ||
                      !_videoController!.value.isInitialized))
                Text('動画を読み込み中...'),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _videoController != null && _videoController!.value.isInitialized
              ? FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                  child: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                )
              : null,
    );
  }
}
