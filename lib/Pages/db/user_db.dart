import 'package:get_storage/get_storage.dart';
import 'package:wisibility/main.dart';

class MongoUserDB {
  static final box = GetStorage();

  static Future<String?> signUp(String email, String password) async {
    final existingUser = await usersCollection.findOne({'email': email});
    if (existingUser != null) {
      return 'User already exists.';
    }
    await usersCollection.insertOne({
      'email': email,
      'password': password,
    });
    return null;
  }

  static Future<String?> login(String email, String password, {bool rememberMe = false}) async {
    final user = await usersCollection.findOne({'email': email});
    if (user == null) {
      return 'User not found.';
    }
    if (user['password'] != password) {
      return 'Invalid password.';
    }

    if (rememberMe) {
      box.write('currentUser', email);
    } else {
      box.remove('currentUser');
    }

    return null;
  }

  static Future<void> logout() async {
    box.remove('currentUser');
  }

  static String? getCurrentUser() {
    return box.read('currentUser');
  }
}
