import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(),
);