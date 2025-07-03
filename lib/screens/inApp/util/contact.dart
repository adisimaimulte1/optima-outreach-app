import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/ai/navigator/trigger_proxy.dart';
import 'package:optima/screens/inApp/widgets/contact/bouncy_contact_info.dart';
import 'package:optima/screens/inApp/widgets/contact/tutorial_cards.dart';

import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/globals.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => ContactScreenState();
}

class ContactScreenState extends State<ContactScreen> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenRegistry.register<ContactScreenState>(ScreenType.contact, widget.key as GlobalKey<ContactScreenState>);
    });

    super.initState();
  }

  @override
  void dispose() {
    ScreenRegistry.unregister(ScreenType.contact);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: ContactScreen,
      builder: (context, isMinimized, scale) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAboutSection(context),
                  _buildContactSection(context),
                  TutorialCards(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _title('About Us'),
          SizedBox(height: 10),
          _buildAboutText(),
        ],
      ),
    );
  }

  Widget _buildAboutText() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25 * screenScaleNotifier.value),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(text: "We are "),
            TextSpan(
              text: "Optima",
              style: TextStyle(
                color: textHighlightedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ", your best companion for optimizing outreach and event management. ",
            ),
            TextSpan(
              text: "Revolutionizing",
              style: TextStyle(
                color: textHighlightedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: " event planning with the world's first app to ",
            ),
            TextSpan(
              text: "unify",
              style: TextStyle(
                color: textHighlightedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: " all your planning needs.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      children: [
        _title('Contact Us'),
        const SizedBox(height: 10),

        BouncyContactInfo(icon: Icons.phone, info: '  Phone Number', url: 'tel:+40720781448'),
        TriggerProxy(
          key: phoneTriggerKey,
          onTriggered: () => launchUrl(Uri.parse('tel:+40720781448')),
        ),

        BouncyContactInfo(icon: Icons.email, info: '  Email Address', url: 'mailto:adrian.c.contras@gmail.com?subject=Optima%20Support&body=Hi%20Optima%20team,%0A%0A'),
        TriggerProxy(
          key: emailTriggerKey,
          onTriggered: () => launchUrl(Uri.parse('mailto:adrian.c.contras@gmail.com?subject=Optima%20Support&body=Hi%20Optima%20team,%0A%0A')),
        ),

        BouncyContactInfo(icon: Icons.link, info: 'Official Website', url: 'https://adisimaimulte1.github.io/optima-official-site/'),
        TriggerProxy(
          key: websiteTriggerKey,
          onTriggered: () => launchUrl(Uri.parse('https://adisimaimulte1.github.io/optima-official-site/')),
        ),

        const SizedBox(height: 10),
      ],
    );
  }



  Widget _title(String text) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Container(height: 2, width: text.length.toDouble() * 16, color: Colors.white24),
      ],
    );
  }
}



