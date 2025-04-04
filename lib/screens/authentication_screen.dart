import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:particles_flutter/particles_flutter.dart';

import 'inApp/dashboard.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;

  String _email = '';
  String _password = '';
  String? _emailError;
  String? _passwordError;

  String? _errorMessage;
  bool _loading = false;
  bool _obscurePassword = true;

  String _loadingText = 'Waiting for email verification...';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }



  bool _validateEmail(String value) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }

  bool _validateInputs() {
    _emailError = null;
    _passwordError = null;

    if (_email
        .trim()
        .isEmpty) {
      _emailError = 'Email is required';
      return false;
    }
    if (!_validateEmail(_email.trim())) {
      _emailError = 'Enter a valid email';
      return false;
    }

    if (_password
        .trim()
        .isEmpty) {
      _passwordError = 'Password is required';
      return false;
    }
    if (_password.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
      return false;
    }

    return true;
  }



  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // collapses keyboard

    if (!_validateInputs()) {
      setState(() {});
      return;
    }

    setState(() {
      _loading = true;
      if (!_isLogin) { _loadingText = 'Waiting for email verification...'; }
      else { _loadingText = 'Logging into the account...'; }
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      _errorMessage = null;

      final success = _isLogin
          ? await _login(auth)
          : await _register(auth);

      if (!mounted || !success) return;
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = (e.code == 'user-not-found')
            ? 'No account found. Please register.'
            : e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<bool> _login(FirebaseAuth auth) async {
    try {
      final result = await auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      await result.user?.reload();
      if (!auth.currentUser!.emailVerified) {
        await auth.signOut();
        setState(() {
          _errorMessage = 'Please verify your email before logging in.';
        });
        return false;
      }

      return true;
    } on FirebaseAuthException catch (e) {
      await _handleLoginError(e);
      return false;
    }
  }

  Future<bool> _register(FirebaseAuth auth) async {
    try {
      final methods = await auth.fetchSignInMethodsForEmail(_email);

      if (methods.contains('password')) {
        try {
          // Attempt to log in — may already exist but unverified
          final loginResult = await auth.signInWithEmailAndPassword(
            email: _email,
            password: _password,
          );

          final user = loginResult.user;

          if (user != null && !user.emailVerified) {
            await user.sendEmailVerification();
            _showVerificationSnackbar();
            await _waitForEmailVerification(auth);
            return user.emailVerified;
          } else {
            setState(() {
              _errorMessage = 'This email is already verified.';
            });
            return false;
          }
        } on FirebaseAuthException catch (e) {
          setState(() {
            _errorMessage = 'Email already in use.';
          });
          return false;
        }
      } else if (methods.isNotEmpty) {
        setState(() {
          _errorMessage = 'This email is registered using another method.';
        });
        return false;
      }

      // Email not in use — safe to register
      final result = await auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      final user = result.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showVerificationSnackbar();
        await _waitForEmailVerification(auth);
        return user.emailVerified;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == "channel-error" ||
          (e.code == 'invalid-credential' && _password.length < 8)) {
        _validateInputs();
        setState(() {});
      } else {
        setState(() {
          _errorMessage = e.message;
        });
      }
      return false;
    }
  }




  Future<void> _openWebsite(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _handleLoginError(FirebaseAuthException e) async {
    if (e.code == 'invalid-credential' && _password.length >= 8) {
      setState(() {
        _errorMessage = 'Login failed: No account found. Please register.';
      });
    } else if (e.code == 'wrong-password') {
      setState(() {
        _errorMessage = 'Incorrect password. Please try again.';
      });
    } else if (e.code == "channel-error" ||
        (e.code == 'invalid-credential' && _password.length < 8)) {
      _validateInputs();
      setState(() {});
    } else if (e.code == 'too-many-requests') {
      setState(() {
        _errorMessage = 'Too many attempts. Please wait 30 seconds.';
      });
      await Future.delayed(const Duration(seconds: 30));
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _showVerificationSnackbar() {
    final isDark = MediaQuery
        .of(context)
        .platformBrightness == Brightness.dark;
    final snackColor = isDark ? Colors.grey[900] : Colors.grey[200];
    final textColor = isDark ? Colors.white : Colors.black;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: snackColor,
        content: responsiveText(
          'A verification email has been sent. Please check your inbox.',
          maxWidthFraction: 0.9,
          style: TextStyle(color: textColor),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _waitForEmailVerification(FirebaseAuth auth) async {
    int tries = 0;

    while (tries < 300) {
      await Future.delayed(const Duration(seconds: 1));

      try {
        await auth.currentUser?.reload();
        final refreshedUser = auth.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          _navigateToHome();
          return;
        }
      } catch (e) { break; }
      tries++;
    }

    // After timeout, check once more — maybe Firebase was slow
    await auth.currentUser?.reload();
    final finalUser = auth.currentUser;
    if (finalUser != null && finalUser.emailVerified) {
      _navigateToHome();
      return;
    }

    // Sign out and reset to registration state
    await FirebaseAuth.instance.signOut();
    setState(() {
      _isLogin = false;
      _emailError = null;
      _passwordError = null;
      _loading = false;
      _errorMessage = 'Email verification expired. Please register again.';
    });
  }



  void _navigateToHome()
  {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
        const DashboardScreen(),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _loadingText = 'Signing in with Google...';
      _errorMessage = null;
    });

    try {
      // always sign out first so the user is prompted to pick an account
      await GoogleSignIn().signOut();

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _loading = false;
          _errorMessage = 'Google sign-in was cancelled.';
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNew) { _openWebsite("https://adisimaimulte1.github.io/optima-verification-site/?mode=verifyEmail&oobCode=love"); }

      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration themedInput(String label, Color fgColor, Color inputBg) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: fgColor.withOpacity(0.8)),
      filled: true,
      fillColor: inputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: fgColor.withOpacity(0.6)),
      ),
    );
  }

  Widget responsiveText(String text, {
    required double maxWidthFraction,
    required TextStyle style,
    TextAlign align = TextAlign.center,
  })
  {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    return SizedBox(
      width: screenWidth * maxWidthFraction,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: style,
          textAlign: align,
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;
    final inputBg = isDark ? Colors.grey[900] : Colors.grey[100];

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _buildParticleBackground(context),
          _buildFormUI(bgColor, fgColor, inputBg),
          if (_loading) _buildLoadingOverlay(bgColor, fgColor),
        ],
      ),
    );
  }

  Widget _buildFormUI(Color bgColor, Color fgColor, Color? inputBg) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Opacity(
          opacity: _loading ? 0.6 : 1.0,
          child: AbsorbPointer(
            absorbing: _loading,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      responsiveText(
                        'OPTIMA',
                        maxWidthFraction: 0.55,
                        style: TextStyle(
                          fontSize: 68,
                          fontFamily: 'Tusker',
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                          letterSpacing: 1.4,
                        ),
                      ),

                      Positioned(
                        top: 3.5,
                        right: MediaQuery.of(context).size.width / 2 - 217,
                        child: responsiveText(
                          '™',
                          maxWidthFraction: 0.05,
                          style: TextStyle(
                            fontSize: 32,
                            color: fgColor.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 12),
                  responsiveText(
                    _isLogin ? 'Login to your account' : 'Create a new account',
                    maxWidthFraction: 0.4,
                    style: TextStyle(
                      fontSize: 16,
                      color: fgColor.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildEmailField(fgColor, inputBg!),
                  const SizedBox(height: 16),
                  _buildPasswordField(fgColor, inputBg),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: responsiveText(
                        _errorMessage!,
                        maxWidthFraction: 0.9,
                        style: const TextStyle(color: Colors.red),
                        align: TextAlign.center,
                      ),
                    ),
                  _buildActionButtons(bgColor, fgColor),
                  const SizedBox(height: 12),
                  _buildGoogleButton(bgColor, fgColor),
                  const SizedBox(height: 20),
                  _buildToggleTextButton(fgColor),
                  if (_isLogin) _buildForgotPasswordButton(fgColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(Color fgColor, Color inputBg) {
    return TextFormField(
      key: const ValueKey('email'),
      style: TextStyle(color: fgColor),
      decoration: InputDecoration(
        label: responsiveText(
          'Email',
          maxWidthFraction: 0.1,
          style: TextStyle(color: fgColor.withOpacity(0.8)),
          align: TextAlign.left,
        ),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fgColor.withOpacity(0.6)),
        ),
        errorText: _emailError,
      ),

      keyboardType: TextInputType.emailAddress,
      onChanged: (value) => _email = value.trim(),
    );
  }

  Widget _buildPasswordField(Color fgColor, Color inputBg) {
    return TextFormField(
      key: const ValueKey('password'),
      style: TextStyle(color: fgColor),
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        label: Align(
          alignment: Alignment.centerLeft,
          child: responsiveText(
            'Password',
            maxWidthFraction: 0.18,
            style: TextStyle(color: fgColor.withOpacity(0.8)),
            align: TextAlign.left,
          ),
        ),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fgColor.withOpacity(0.6)),
        ),
        errorText: _passwordError,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: fgColor.withOpacity(0.6),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      onChanged: (value) => _password = value,
    );
  }

  Widget _buildActionButtons(Color bgColor, Color fgColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: fgColor,
          foregroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: responsiveText(
          _isLogin ? 'Login' : 'Register',
          maxWidthFraction:
          _isLogin ? 0.1 : 0.15,
          style: TextStyle(color: bgColor),
        ),

      ),
    );
  }

  Widget _buildGoogleButton(Color bgColor, Color fgColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _signInWithGoogle,
        icon: Container(
          height: 24,
          width: 24,
          margin: const EdgeInsets.only(right: 12),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Image.asset('assets/images/icons/google_icon.png'),
          ),
        ),
        label: responsiveText(
          'Sign in with Google',
          maxWidthFraction: 0.35,
          style: TextStyle(
            color: bgColor, // or your button label style
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: fgColor,
          foregroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 1,
        ),
      ),
    );
  }

  Widget _buildToggleTextButton(Color fgColor) {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          _errorMessage = null;
          _emailError = null;
          _passwordError = null;
        });
      },
      child: responsiveText(
        _isLogin ? 'Don\'t have an account? Register' : 'Already registered? Login',
        maxWidthFraction:
        _isLogin ? 0.55 : 0.45,
        style: TextStyle(color: fgColor.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildLoadingOverlay(Color bgColor, Color fgColor) {
    return Positioned.fill(
      child: Container(
        color: fgColor.withOpacity(0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              responsiveText(
                _loadingText,
                maxWidthFraction: 0.9,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // only show cancel button in login flow
              if (_isLogin)
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    setState(() {
                      _loading = false;
                      _errorMessage = 'Verification cancelled.';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: fgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: responsiveText(
                    'Cancel',
                    maxWidthFraction: 0.3,
                    style: TextStyle(color: fgColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(Color fgColor) {
    final isDark = MediaQuery
        .of(context)
        .platformBrightness == Brightness.dark;
    final snackColor = isDark ? Colors.grey[900] : Colors.grey[200];
    final textColor = isDark ? Colors.white : Colors.black;

    return TextButton(
      onPressed: () async {
        if (_email.trim().isEmpty || !_validateEmail(_email.trim())) {
          setState(() {
            _emailError = 'Enter a valid email to reset your password';
          });
          return;
        }

        setState(() {
          _emailError = null;
        });

        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.trim());


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: responsiveText(
                'Password reset email sent. Check your inbox.',
                maxWidthFraction: 0.95,
                style: TextStyle(color: textColor),
              ),
              backgroundColor: snackColor,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to send password reset email. Try again.';
          });
        }
      },
      child: responsiveText(
        'Forgot password?',
        maxWidthFraction: 0.4,
        style: TextStyle(color: fgColor.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildParticleBackground(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final particleColor = isDark
        ? Colors.white.withOpacity(0.3)
        : Colors.black.withOpacity(0.3);

    return IgnorePointer(
      ignoring: true,
      child: CircularParticle(
        key: UniqueKey(),
        awayRadius: 80,
        numberOfParticles: 110,
        speedOfParticles: 1.2,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        onTapAnimation: false,
        particleColor: particleColor,
        awayAnimationDuration: const Duration(milliseconds: 600),
        maxParticleSize: 4,
        isRandSize: true,
        isRandomColor: false,
        connectDots: false,
      ),
    );
  }





  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }
}
