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
import 'package:pocketbase/pocketbase.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthScreen extends StatelessWidget {
  final pb = PocketBase(const String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://127.0.0.1:8090',
  ));

  AuthScreen({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
    try {
      final _ = await pb.collection('users').authWithPassword(
            data.name,
            data.password,
          );
      return null; // 成功時は null を返す
    } catch (e) {
      return 'ログインに失敗しました: ${e.toString()}';
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
        // ログイン後の画面遷移など
        Navigator.of(context).pushReplacementNamed('/home');
      },
    );
  }
}
