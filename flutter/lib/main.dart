import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_application/auth_screen.dart';
import 'package:flutter_application/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'),
        Locale('ja'),
        Locale('fr'),
      ],
      path: 'assets/translations',
      fallbackLocale: Locale('en'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // ルート設定: ログイン後はHomeScreenに遷移
      initialRoute: '/',
      routes: {
        '/': (context) => Scaffold(
              appBar: AppBar(
                title: Text('ケンカル 配信テスト'),
              ),
              body: AuthScreen(),
            ),
        '/home': (context) => const HomeScreen(),
      },
// HomeScreenはhome_screen.dartに分離
    );
  }
}

// 通知テストウィジェットは notification_test.dart から直接呼び出し
