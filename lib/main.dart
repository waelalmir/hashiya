import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import 'app_shell.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  await Store.load();
  await AppData.load();
  runApp(const HashiyaApp());
}

class HashiyaApp extends StatelessWidget {
  const HashiyaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'حاشية',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(),
        home: const AppShell(),
      );
}
