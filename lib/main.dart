import 'package:fluent_ui/fluent_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wisibility/Pages/auth/login.dart';
import 'package:wisibility/navBar.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  var box = await Hive.openBox('userBox');

  bool isLoggedIn = box.get('isLoggedIn', defaultValue: false);

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Offline Login Fluent',
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        accentColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xfff1cd73), // Yellow background
      ),
      home: widget.isLoggedIn
          ? NavBar(
        isDarkMode: isDarkMode,
        onToggleTheme: toggleTheme,
      )
          : AuthPage(
        isDarkMode: isDarkMode,
        toggleTheme: toggleTheme,
      ),
    );
  }
}


// 0xFFeec72e
// 0xFF85c48d