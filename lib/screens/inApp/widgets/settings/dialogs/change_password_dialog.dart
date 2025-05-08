import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class ChangePasswordDialog {
  static void show(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (isGoogleUser) {
      showGoogleSignInPopUp(context);
    } else {
      showChangePasswordDialog(context, user);
    }
  }

  static void showGoogleSignInPopUp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Change Password",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "You cannot change the password because you signed in using Google. Please manage your password directly through Google.",
            style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButtonWithoutIcon(
            label: "OK",
            onPressed: () => Navigator.pop(context),
            backgroundColor: textHighlightedColor,
            foregroundColor: inAppForegroundColor,
            fontSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ],
      ),
    );
  }

  static void showChangePasswordDialog(BuildContext context, User? user) {
    final oldController = TextEditingController();
    final newController = TextEditingController();


    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Change Password", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: standardInputDecoration(hint: "", label: "Current Password"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: standardInputDecoration(hint: "", label: "New Password"),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 8, right: 12),
        actions: [
          TextButtonWithoutIcon(
            label: "Change",
            onPressed: () async {
              final oldPassword = oldController.text.trim();
              final newPassword = newController.text.trim();

              if (oldPassword.isEmpty || newPassword.isEmpty) {
                _showSnackBar(context, "Both fields are required.", Colors.orange);
                return;
              }

              try {
                final credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: oldPassword,
                );

                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);
                await user.reload();

                _showSnackBar(context, "Password changed successfully!", Colors.green);
                Navigator.pop(context);
              } on FirebaseAuthException catch (e) {
                _showSnackBar(context, "Error: ${e.message}", Colors.red);
              }
            },
            backgroundColor: textHighlightedColor,
            foregroundColor: inAppForegroundColor,
            fontSize: 17,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          )
        ],
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 6,
        duration: const Duration(seconds: 2),
        content: Center(
          child: Text(
            message,
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
