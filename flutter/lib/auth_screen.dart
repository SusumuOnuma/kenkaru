// Copyright (C) 2025  SUSUMU ONUMA
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'pb_instance.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
    try {
      final _ = await pb.collection('users').authWithPassword(
            data.name,
            data.password,
          );
      // ログイン成功後に動画通知をスケジュール
      await _scheduleVideoNotification();
      return null; // 成功時は null を返す
    } catch (e) {
      return 'ログインに失敗しました: ${e.toString()}';
    }
  }

  Future<void> _scheduleVideoNotification() async {
    try {
      // 1. ファイルトークン取得
      final fileToken = await pb.files.getToken();
      // 2. 動画レコード取得
      final record = await pb.collection('videos').getOne('m32x53yhl908bv0');
      // 3. ProtectedファイルURL生成
      final videoUrl = pb.files
          .getURL(record, record.getStringValue('file'), token: fileToken);
      // 4. notificationsに1分後の通知を追加
      final now = DateTime.now();
      final scheduledAt = now.add(Duration(minutes: 1));
      final userId = pb.authStore.record?.id;
      await pb.collection('notifications').create(body: {
        'user': userId,
        'title': '新着動画',
        'body': '動画を再生してみましょう',
        'video_url': videoUrl,
        'scheduled_at': scheduledAt.toIso8601String(),
        'sent': false,
        'read': false,
      });
    } catch (e) {
      // エラー時はログ出力のみ（UIには表示しない）
      debugPrint('動画通知スケジュール失敗: $e');
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    try {
      final body = <String, dynamic>{
        "email": data.name,
        "password": data.password,
        "passwordConfirm": data.password,
      };
      await pb.collection('users').create(body: body);
      return null; // 成功時は null を返す
    } catch (e) {
      return '登録に失敗しました: ${e.toString()}';
    }
  }

  Future<String?> _recoverPassword(String name) async {
    // パスワードリカバリーの実装（必要に応じて）
    return 'パスワードリカバリーは未実装です';
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'My App',
      messages: LoginMessages(
        passwordHint: 'password'.tr(),
        confirmPasswordHint: 'confirm_password'.tr(),
        loginButton: 'login'.tr(),
        signupButton: 'signup'.tr(),
        forgotPasswordButton: 'recover_password'.tr(),
        recoverPasswordButton: 'recover_password'.tr(),
        goBackButton: 'go_back'.tr(),
        confirmPasswordError: 'confirm_password_error'.tr(),
        recoverPasswordDescription: 'recover_password_description'.tr(),
        recoverPasswordSuccess: 'recover_password_success'.tr(),
      ),
      onLogin: _authUser,
      onSignup: _signupUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: () {
        // ログイン後の画面遷移でHomeScreenへ
        Navigator.of(context).pushReplacementNamed('/home');
      },
    );
  }
}
