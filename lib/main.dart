import 'package:fluent_ui/fluent_ui.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import 'Pages/auth/login.dart';
import 'Pages/db/db_keys.dart';
import 'navBar.dart';

late mongo.Db db;
late mongo.DbCollection usersCollection;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  db = await mongo.Db.create(dbLink);
  await db.open();
  print('✅ Connected to DB: ${db.databaseName}');

  usersCollection = db.collection('Users');

  final box = GetStorage();
  final currentUser = box.read('currentUser');

  runApp(MyApp(isLoggedIn: currentUser != null));
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
      title: 'MongoDB Fluent Auth',
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        accentColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xfff1cd73),
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


// import 'package:flutter/material.dart';
// import 'package:mongo_dart/mongo_dart.dart' as mongo;
//
// // Global DB & collection
// late mongo.Db db;
// late mongo.DbCollection usersCollection;
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   db = await mongo.Db.create(
//     "mongodb+srv://cgarnaik:RaSCRZTdwaMYGE8R@wisibilitydb.n6hsddw.mongodb.net/WRoot?retryWrites=true&w=majority",
//   );
//   await db.open();
//
//   usersCollection = db.collection('Users');
//
//   // Fetch initial users
//   final users = await usersCollection.find().toList();
//
//   runApp(MyApp(users: users));
// }
//
// class MyApp extends StatefulWidget {
//   final List users;
//
//   const MyApp({Key? key, required this.users}) : super(key: key);
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   List users = [];
//
//   @override
//   void initState() {
//     super.initState();
//     users = widget.users;
//   }
//
//   Future<void> addUser() async {
//     final newUser = {
//       "name": "User ${DateTime.now().millisecondsSinceEpoch}",
//       "email": "user${users.length + 1}@example.com",
//     };
//
//     // ✅ Always insert a fresh copy to prevent _id type mutation issues
//     await usersCollection.insertOne({...newUser});
//
//     // Fetch updated list
//     final updatedUsers = await usersCollection.find().toList();
//
//     setState(() {
//       users = updatedUsers;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'MongoDB Flutter Demo',
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Users from MongoDB'),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.add),
//               onPressed: addUser,
//             ),
//           ],
//         ),
//         body: users.isEmpty
//             ? Center(child: Text('No users found'))
//             : ListView.builder(
//           itemCount: users.length,
//           itemBuilder: (context, index) {
//             final user = users[index];
//             return ListTile(
//               title: Text(user['name'] ?? 'No name'),
//               subtitle: Text(user['email'] ?? 'No email'),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
