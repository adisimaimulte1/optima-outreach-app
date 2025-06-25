import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optima/globals.dart';

import 'package:optima/screens/beforeApp/splash_screen_adaptive.dart';
import 'package:optima/screens/beforeApp/authentication_screen.dart';
import 'package:optima/screens/inApp/util/aichat.dart';
import 'package:optima/screens/inApp/util/contact.dart';
import 'package:optima/screens/inApp/util/dashboard.dart';
import 'package:optima/screens/inApp/util/events.dart';
import 'package:optima/screens/inApp/util/users.dart';
import 'package:optima/screens/inApp/util/settings.dart';
import 'package:optima/screens/inApp/widgets/menu/menu_controller.dart' as custom_menu;
import 'package:optima/screens/inApp/widgets/menu/menu_overlay.dart';
import 'package:optima/services/sessions/session_service.dart';


class ChooseScreen extends StatefulWidget {
  const ChooseScreen({super.key});

  @override
  State<ChooseScreen> createState() => _ChooseScreenState();
}

class _ChooseScreenState extends State<ChooseScreen> with WidgetsBindingObserver {
  bool _keyboardVisible = false;
  Timer? _immersiveTimer;




  @override
  void initState() {
    super.initState();

    popupStackCount.value = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      preCacheTutorialImages(context);
    });

    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _startImmersiveTimer() {
    _immersiveTimer?.cancel();
    _immersiveTimer = Timer(const Duration(seconds: 1), () {
      if (!_keyboardVisible) SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final isKeyboardNowVisible = bottomInset > 0;

    if (_keyboardVisible != isKeyboardNowVisible) {
      _keyboardVisible = isKeyboardNowVisible;

      if (!_keyboardVisible) {
        _startImmersiveTimer();
      } else {
        _immersiveTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _immersiveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }




  Future<UserState> _getUserState() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        await user!.reload();
        if (user!.emailVerified) {
          return UserState.authenticated;

        }
      } catch (e) {}
      return UserState.unverified;
    }

    return UserState.unauthenticated;
  }

  Widget _buildAuthenticatedScreen() {
    return ValueListenableBuilder<UniqueKey>(
      valueListenable: appReloadKey,
      builder: (_, key, __) {
        return KeyedSubtree(
          key: key,
          child: ValueListenableBuilder<ScreenType>(
            valueListenable: selectedScreenNotifier,
            builder: (context, selectedScreen, _) {
              switch (selectedScreen) {
                case ScreenType.dashboard:
                  custom_menu.MenuController.instance.selectSource(DashboardScreen);
                  return const DashboardScreen();
                case ScreenType.settings:
                  custom_menu.MenuController.instance.selectSource(SettingsScreen);
                  return const SettingsScreen();
                case ScreenType.chat:
                  custom_menu.MenuController.instance.selectSource(ChatScreen);
                  return const ChatScreen();
                case ScreenType.events:
                  custom_menu.MenuController.instance.selectSource(EventsScreen);
                  return const EventsScreen();
                case ScreenType.users:
                  custom_menu.MenuController.instance.selectSource(UsersScreen);
                  return const UsersScreen();
                case ScreenType.contact:
                  custom_menu.MenuController.instance.selectSource(ContactScreen);
                  return const ContactScreen();
                case ScreenType.menu:
                  return const DashboardScreen();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildByUserState(UserState state) {
    switch (state) {
      case UserState.authenticated: {
        jamieEnabledNotifier.value = jamieEnabled;
        if (isInitialLaunch) {
          SessionService().updateLastActive();

          isInitialLaunch = false;
        } return _buildAuthenticatedScreen();

      } case UserState.unauthenticated: {
        jamieEnabledNotifier.value = false;
          if (isInitialLaunch) {
            isInitialLaunch = false;
            return const AnimatedSplashScreen();
          } return const AuthScreen();

      } case UserState.unverified: {
        jamieEnabledNotifier.value = false;
        return const AuthScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserState>(
      future: _getUserState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return isInitialLaunch && FirebaseAuth.instance.currentUser == null ?
            Scaffold(
              backgroundColor: isDarkModeNotifier.value ? textHighlightedColor : const Color(0xFFFFCD32),
            ) :
            const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }

        final state = snapshot.data!;

        return AppMenuOverlay(
          child: _buildByUserState(state),
        );
      },
    );
  }
}
