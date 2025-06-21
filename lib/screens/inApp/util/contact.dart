import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/contact/tutorial_cards.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/globals.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

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
        SizedBox(height: 10),
        _buildContactInfo(Icons.phone, '  Phone Number', 'tel:+40720781448'),
        _buildContactInfo(Icons.email, '  Email Address', 'mailto:adrian.c.contras@gmail.com?subject=Optima%20Support&body=Hi%20Optima%20team,%0A%0A'),
        _buildContactInfo(Icons.link, 'Official Website', 'https://adisimaimulte1.github.io/optima-official-site/'),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String info, String url) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textHighlightedColor,
              size: 30,
            ),
            SizedBox(width: 8),
            Text(
              info,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);

      if (uri.scheme == 'mailto') {
        final Uri emailLaunchUri = Uri(
          scheme: 'mailto',
          path: uri.path,
          query: uri.query,
        );
        await launchUrl(emailLaunchUri);
      }
      else if (uri.scheme == 'http' || uri.scheme == 'https') {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
      else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

}
