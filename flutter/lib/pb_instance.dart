import 'package:pocketbase/pocketbase.dart';

final pb = PocketBase(const String.fromEnvironment('POCKETBASE_URL', defaultValue: 'http://127.0.0.1:8090'));
