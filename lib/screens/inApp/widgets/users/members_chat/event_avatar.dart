import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class EventAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final Color borderColor;
  final bool showEditIcon;
  final VoidCallback? onEditTap;

  const EventAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 64,
    required this.borderColor,
    this.showEditIcon = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      try {
        if (imageUrl!.startsWith('http')) {
          return _buildStack(_imageAvatar(NetworkImage(imageUrl!)));
        } else {
          final bytes = base64Decode(imageUrl!.split(',').last);
          return _buildStack(_imageAvatar(MemoryImage(bytes)));
        }
      } catch (_) {
        return _buildStack(_initialsAvatar());
      }
    }
    return _buildStack(_initialsAvatar());
  }

  Widget _buildStack(Widget avatar) {
    final content = Stack(
      alignment: Alignment.center,
      children: [
        avatar,
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(size * 0.04),
              decoration: BoxDecoration(
                color: inAppForegroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: size * 0.04),
              ),
              child: Icon(
                Icons.edit,
                size: size * 0.21,
                color: borderColor,
              ),
            ),
          ),
      ],
    );

    return showEditIcon
        ? GestureDetector(
      onTap: onEditTap,
      child: SizedBox(
        width: size,
        height: size,
        child: content,
      ),
    )
        : content;
  }

  Widget _imageAvatar(ImageProvider image) {
    final borderWidth = size * 0.09;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(
        child: Image(
          key: ValueKey(imageUrl),
          image: image,
          fit: BoxFit.cover,
          width: size,
          height: size,
          gaplessPlayback: true,
        ),
      ),
    );
  }


  Widget _initialsAvatar() {
    final borderWidth = size * 0.1;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: borderColor,
        ),
      ),
    );
  }
}
