import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'main_page.dart';

class MyApp extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: MainPage(),
    );
  }
}
