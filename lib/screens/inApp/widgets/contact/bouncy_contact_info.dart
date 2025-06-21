
import 'package:flutter/cupertino.dart';
import 'package:optima/globals.dart';
import 'package:url_launcher/url_launcher.dart';

class BouncyContactInfo extends StatefulWidget {
  final IconData icon;
  final String info;
  final String url;

  const BouncyContactInfo({
    super.key,
    required this.icon,
    required this.info,
    required this.url,
  });

  @override
  State<BouncyContactInfo> createState() => BouncyContactInfoState();
}

class BouncyContactInfoState extends State<BouncyContactInfo> {
  double _scale = 1.0;

  void _onTapDown(_) {
    setState(() => _scale = 0.85);
  }

  void _onTapUp(_) async {
    await Future.delayed(const Duration(milliseconds: 120));
    setState(() => _scale = 1.0);
    await Future.delayed(const Duration(milliseconds: 120));
    _launchURL(widget.url);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: textHighlightedColor, size: 30),
              const SizedBox(width: 8),
              Text(
                widget.info,
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
      ),
    );
  }

  void _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'mailto') {
        await launchUrl(uri);
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }
}

