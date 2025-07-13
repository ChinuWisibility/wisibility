import 'package:fluent_ui/fluent_ui.dart';
import 'package:lottie/lottie.dart';
import 'package:wisibility/Pages/db/user_db.dart';
import 'package:wisibility/navBar.dart';


class AuthPage extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool) toggleTheme;

  const AuthPage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool rememberMe = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _showInfo(String msg) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(msg),
        severity: InfoBarSeverity.info,
      ),
    );
  }

  Future<void> _handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showInfo('Please fill all fields.');
      return;
    }

    if (isLogin) {
      // ✅ Pass rememberMe here!
      final result = await MongoUserDB.login(
        email,
        password,
        rememberMe: rememberMe,
      );

      if (result == null) {
        _showInfo('Login successful!');
        Navigator.pushReplacement(
          context,
          FluentPageRoute(
            builder: (_) => NavBar(
              isDarkMode: widget.isDarkMode,
              onToggleTheme: widget.toggleTheme,
            ),
          ),
        );
      } else {
        _showInfo(result);
      }
    } else {
      final result = await MongoUserDB.signUp(email, password);
      if (result == null) {
        _showInfo('Sign up successful! Now sign in.');
        setState(() {
          isLogin = true;
        });
      } else {
        _showInfo(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: Row(
        children: [
// LEFT PANEL
          Expanded(
            flex: 3,
            child: Container(
              color: Color(0xFF85c48d),
              child: Center(
                child: Lottie.asset(
                  'assets/auth.json',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
// RIGHT PANEL
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 80),
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/T_Wisibility.png',
                            height: 40,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Wisibility With You',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Text(
                        isLogin ? 'Welcome back' : 'Create an account',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isLogin
                            ? 'Please enter your details'
                            : 'Sign up to get started',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      TextBox(
                        controller: emailController,
                        placeholder: 'Email address',
                      ),
                      const SizedBox(height: 20),
                      TextBox(
                        controller: passwordController,
                        placeholder: 'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            checked: rememberMe,
                            onChanged: (v) => setState(() => rememberMe = v!),
                          ),
                          const Text('  Remember Me'),
                          const Spacer(),
                          HyperlinkButton(
                            child: const Text('Forgot password'),
                            onPressed: () {
                              _showInfo('Forgot password clicked!');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        style: ButtonStyle(
                          backgroundColor: ButtonState.all(Color(0xFF85c48d)),
                          foregroundColor: ButtonState.all(Colors.white),
                          padding: ButtonState.all(
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isLogin ? 'Sign in' : 'Sign up',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        onPressed: _handleAuth,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLogin
                                ? 'Don\'t have an account? '
                                : 'Already have an account? ',
                          ),
                          HyperlinkButton(
                            child: Text(isLogin ? 'Sign up' : 'Sign in'),
                            onPressed: () =>
                                setState(() => isLogin = !isLogin),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




