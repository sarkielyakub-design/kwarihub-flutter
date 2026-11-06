import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
class KwariHubApp extends StatelessWidget {
  const KwariHubApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp.router(title: 'KwariHub', debugShowCheckedModeBanner: false, theme: AppTheme.light, routerConfig: appRouter);
}
