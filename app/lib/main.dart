import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const ServerMonitorApp());
}

class ServerMonitorApp extends StatelessWidget {
  const ServerMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardPage(),
    );
  }
}
