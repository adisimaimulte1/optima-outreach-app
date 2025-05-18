import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationBlock extends StatefulWidget {
  final String address;

  const LocationBlock({super.key, required this.address});

  @override
  State<LocationBlock> createState() => LocationBlockState();
}

class LocationBlockState extends State<LocationBlock> {
  double _scale = 1.0;

  void _openGoogleEarth() async {
    final query = Uri.encodeComponent(widget.address);
    final googleEarthUrl = Uri.parse('https://earth.google.com/web/search/$query');

    if (await canLaunchUrl(googleEarthUrl)) {
      await launchUrl(googleEarthUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Earth')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: GestureDetector(
          onTap: _openGoogleEarth,
          onTapDown: (_) => setState(() => _scale = 0.9),
          onTapUp: (_) => setState(() => _scale = 1.0),
          onTapCancel: () => setState(() => _scale = 1.0),
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: textColor.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 32,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.location_on,
                        color: textHighlightedColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.address,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
