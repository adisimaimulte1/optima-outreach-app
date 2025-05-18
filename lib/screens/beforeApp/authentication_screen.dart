import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:optima/screens/beforeApp/widgets/background_particles.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/services/credits/plan_notifier.dart';
import 'package:optima/services/credits/sub_credit_notifier.dart';
import 'package:optima/services/storage/cloud_storage_service.dart';
import 'package:optima/services/credits/credit_notifier.dart';
import 'package:optima/services/storage/local_storage_service.dart';
import 'package:optima/services/sessions/session_service.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:optima/screens/beforeApp/widgets/buttons/bouncy_button.dart';
import 'package:optima/screens/choose_screen.dart';
import 'package:optima/globals.dart';



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
    isFirstDashboardLaunch = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

      _navigateToHome(false);
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDarkModeNotifier.value ? Colors.white : inAppBackgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 6,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Text(
            'A verification email has been sent. Please check your inbox.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textHighlightedColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
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
          _navigateToHome(false);
          return;
        }
      } catch (e) { break; }
      tries++;
    }

    await auth.currentUser?.reload();
    final finalUser = auth.currentUser;
    if (finalUser != null && finalUser.emailVerified) {
      _navigateToHome(false);
      return;
    }

    await FirebaseAuth.instance.signOut();
    setState(() {
      _isLogin = false;
      _emailError = null;
      _passwordError = null;
      _loading = false;
      _errorMessage = 'Email verification expired. Please register again.';
    });
  }



  void _navigateToHome(bool googleSignIn) {
    selectedScreenNotifier.value = ScreenType.dashboard;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    LocalStorageService().setIsGoogleUser(googleSignIn);
    LocalCache().initializeAndCacheUserData();

    SessionService().registerSession();

    creditNotifier = CreditNotifier();
    subCreditNotifier = SubCreditNotifier();
    selectedPlan = PlanNotifier();

    isFirstDashboardLaunch = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ChooseScreen(),
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
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() async {
          _loading = false;
          _errorMessage = 'Google sign-in was cancelled.';
          await FirebaseAuth.instance.signOut();
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

      await FirebaseAuth.instance.currentUser?.reload();
      final user = userCredential.user;

      if (isNew && user != null) {
        await CloudStorageService().initDatabaseWithUser(user);
        _openWebsite("https://adisimaimulte1.github.io/optima-verification-site/?mode=verifyEmail&oobCode=love");
      }

      if (!mounted) return;
      _navigateToHome(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }








  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkModeNotifier.value ? Colors.black : lightColorPrimary;
    final fgColor = isDarkModeNotifier.value ? Colors.white : inAppBackgroundColor;
    final inputBg = isDarkModeNotifier.value ? Colors.grey[900] : lightColorSecondary;

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const BackgroundParticles(),
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
                        context,
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
                          context,
                          '™',
                          maxWidthFraction: 0.05,
                          style: TextStyle(
                            fontSize: 32,
                            color: fgColor.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _buildEmailField(fgColor, inputBg!),
                  const SizedBox(height: 16),
                  _buildPasswordField(fgColor, inputBg),
                  if (_errorMessage == null) const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: responsiveText(
                        context,
                        _errorMessage!,
                        maxWidthFraction: 0.9,
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold
                        ),
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
      decoration: standardInputDecoration(
        hint: '.',
        label: 'Email',
        fillColor: inputBg,
        labelColor: fgColor,
        borderColor: fgColor,
      ).copyWith(
        errorText: _emailError,
      ),
      keyboardType: TextInputType.emailAddress,
      onChanged: (value) => _email = value.trim(),
    );
  }

  Widget _buildPasswordField(Color fgColor, Color inputBg) {
    return TextFormField(
      key: const ValueKey('password'),
      obscureText: _obscurePassword,
      style: TextStyle(color: fgColor),
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enableSuggestions: false,
      decoration: standardInputDecoration(
        hint: '',
        label: 'Password',
        fillColor: inputBg,
        labelColor: fgColor,
        borderColor: fgColor,
      ).copyWith(
        errorText: _passwordError,
        suffixIcon: IconButton(
          style: TextButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            foregroundColor: fgColor,
            overlayColor: Colors.transparent,
          ),
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: fgColor.withOpacity(0.8),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      onChanged: (value) => _password = value,
    );
  }

  Widget _buildActionButtons(Color bgColor, Color fgColor) {
    return BouncyButton(
      onPressed: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: responsiveText(
            context,
            _isLogin ? 'Login' : 'Register',
            maxWidthFraction: _isLogin ? 0.1 : 0.15,
            style: TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(Color bgColor, Color fgColor) {
    return BouncyButton(
      onPressed: _signInWithGoogle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 24,
              width: 24,
              margin: const EdgeInsets.only(right: 12),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.asset('assets/images/icons/google_icon.png'),
              ),
            ),
            responsiveText(
              context,
              'Sign in with Google',
              maxWidthFraction: 0.35,
              style: TextStyle(
                  color: bgColor,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTextButton(Color fgColor) {
    return TextButton(
      style: TextButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        foregroundColor: fgColor,
        overlayColor: Colors.transparent
      ),
      onPressed: () {
        FocusScope.of(context).unfocus();

        setState(() {
          _isLogin = !_isLogin;
          _errorMessage = null;
          _emailError = null;
          _passwordError = null;
        });
      },
      child: responsiveText(
        context,
        _isLogin ? 'Don\'t have an account? Register' : 'Already registered? Login',
        maxWidthFraction:
        _isLogin ? 0.55 : 0.45,
        style: TextStyle(
            color: fgColor,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(Color bgColor, Color fgColor) {
    return Positioned.fill(
      child: Container(
        color: textColor.withOpacity(0.6),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(Color fgColor) {
    return TextButton(
      style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          foregroundColor: fgColor,
          overlayColor: Colors.transparent
      ),
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
              backgroundColor: isDarkModeNotifier.value ? Colors.white : inAppBackgroundColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 6,
              duration: const Duration(seconds: 1),
              content: Center(
                child: Text(
                  'Password reset email sent. Check your inbox.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textHighlightedColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to send password reset email. Try again.';
          });
        }
      },
      child: responsiveText(
        context,
        'Forgot password?',
        maxWidthFraction: 0.3,
        style: TextStyle(
            color: fgColor,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }

}