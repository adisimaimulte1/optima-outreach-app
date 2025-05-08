import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/cache/local_cache.dart';
import 'package:optima/screens/beforeApp/choose_screen.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class AccountDeleteDialogs {
  static Future<void> showDeleteConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        title: Column(
          children: [
            Icon(Icons.delete_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Delete Account",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          "This will permanently delete all your data and cannot be undone.",
          style: TextStyle(
            color: textColor,
            fontSize: 15.5,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () => Navigator.pop(context, false),
            foregroundColor: Colors.white70,
            fontSize: 16,
            borderColor: Colors.white70,
            borderWidth: 1,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
          TextButtonWithoutIcon(
            label: "Delete",
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.red,
            foregroundColor: inAppForegroundColor,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isGoogleUser) {
        await promptGoogleConfirmation(context);
      } else {
        await promptForPassword(context);
      }
    }
  }

  static Future<void> promptForPassword(BuildContext context) async {
    final passwordController = TextEditingController();
    String? password;

    await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        title: Column(
          children: [
            Icon(Icons.lock_outline, size: 48, color: textHighlightedColor),
            const SizedBox(height: 12),
            Text(
              "Confirm Password",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: TextStyle(color: textColor),
          decoration: standardInputDecoration(hint: "", label: "Password"),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
          TextButtonWithoutIcon(
            label: "Submit",
            onPressed: () async {
              password = passwordController.text.trim();
              if (password != null && password!.isNotEmpty) {
                await deleteAccount(password!, context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: textHighlightedColor,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 6,
                    duration: const Duration(seconds: 1),
                    content: Center(
                      child: Text(
                        "Password cannot be empty.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: inAppForegroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }
              Navigator.pop(context);
            },
            backgroundColor: textHighlightedColor,
            foregroundColor: inAppForegroundColor,
            fontSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );
  }

  static Future<void> promptGoogleConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.only(top: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        title: Column(
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Are you sure?",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          "This action is irreversible.\nAll your data will be permanently deleted.",
          style: TextStyle(
            color: textColor,
            fontSize: 15.5,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "Cancel",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 16,
            borderColor: Colors.white70,
            borderWidth: 1,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
          TextButtonWithoutIcon(
            label: "Delete",
            onPressed: () async {
              Navigator.pop(context);
              await deleteAccount('', context);
            },
            backgroundColor: Colors.red,
            foregroundColor: inAppForegroundColor,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          ),
        ],
      ),
    );
  }

  static Future<void> deleteAccount(String? password, BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseAuthException(message: "No user is logged in.", code: 'user-not-found');
      }

      if (isGoogleUser) {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final googleAuth = await googleUser?.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        await user.reauthenticateWithCredential(credential);
        LocalCache().deleteAll();

      } else if (password != null && password.isNotEmpty) {
        final credential = EmailAuthProvider.credential(email: user.email!, password: password);

        await user.reauthenticateWithCredential(credential);
        LocalCache().deleteAll();

      } else {
        throw FirebaseAuthException(message: "Password is required.", code: 'password-missing');
      }

      await Future.delayed(Duration(milliseconds: 100));

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ChooseScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 6,
          duration: const Duration(seconds: 2),
          content: Center(
            child: Text(
              "Error: \${e.message}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: inAppForegroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 6,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Text(
            "Account deleted successfully.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: inAppForegroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
