import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:optima/globals.dart';


class Member {
  final String id;
  final String displayName;
  final String? photo;
  final String? resolvedPhoto;

  const Member({
    required this.id,
    required this.displayName,
    this.photo,
    this.resolvedPhoto,
  });

  Member withResolvedPhoto(String? value) => Member(
    id: id,
    displayName: displayName,
    photo: photo,
    resolvedPhoto: value,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Member &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              resolvedPhoto == other.resolvedPhoto;

  @override
  int get hashCode => id.hashCode ^ resolvedPhoto.hashCode;
}

class AnimatedAvatarSlot extends StatelessWidget {
  final Member member;
  final Offset targetOffset;
  final Offset centerOffset;
  final double size;
  final Color color;
  final VoidCallback onLong;
  final Duration delay;

  const AnimatedAvatarSlot({
    required this.member,
    required this.targetOffset,
    required this.centerOffset,
    required this.size,
    required this.color,
    required this.onLong,
    required this.delay,
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: centerOffset, end: targetOffset),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (_, pos, child) {
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: child!,
        );
      },
      child: AvatarSlot(
        member: member,
        size: size,
        color: color,
        onLong: onLong,
      ),
    );
  }
}



class AvatarSlot extends StatefulWidget {
  final Member? member;
  final double size;
  final Color color;
  final VoidCallback onLong;

  const AvatarSlot({
    required this.member,
    required this.size,
    required this.color,
    required this.onLong,
    super.key,
  });

  @override
  State<AvatarSlot> createState() => _AvatarSlotState();
}

class _AvatarSlotState extends State<AvatarSlot> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _popController;
  late Animation<double> _scale;
  late Animation<double> _shake;
  late Animation<double> _popScale;
  late Animation<double> _popOpacity;

  Widget? _cachedContent;
  String? _lastResolvedPhoto;

  Timer? _deleteTimer;
  bool _shouldDelete = false;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
    _shake = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.linear),
    );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popScale = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
      parent: _popController,
      curve: Curves.easeInBack,
    ));
    _popOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(_popController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _popController.dispose();
    _deleteTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    _shouldDelete = false;
    _pressController.repeat(reverse: true);

    _deleteTimer = Timer(const Duration(milliseconds: 400), () {
      _shouldDelete = true;
      _popController.forward().whenComplete(() {
        widget.onLong();
      });
    });
  }

  void _cancelHold() {
    _pressController.reset();
    _deleteTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final dashed = widget.member == null;

    return GestureDetector(
      onLongPressStart: dashed ? null : (_) => _startHold(),
      onLongPressEnd: dashed ? null : (_) => _cancelHold(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _popController]),
        builder: (_, child) {
          final shakeRotation = sin(_pressController.value * pi * 6) * _shake.value;
          final scale = _shouldDelete ? _popScale.value : _scale.value;
          final opacity = _shouldDelete ? _popOpacity.value : 1.0;

          return Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: shakeRotation,
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dashed ? Colors.transparent : textSecondaryHighlightedColor,
            border: Border.all(
              color: widget.color,
              width: dashed ? 2 : 3,
            ),
          ),
          alignment: Alignment.center,
          child: _content(dashed),
        ),
      ),
    );
  }

  Widget _content(bool dashed) {
    if (dashed) return Icon(Icons.add, size: 28, color: widget.color);

    final member = widget.member!;
    final displayName = member.displayName;
    final photo = member.resolvedPhoto;

    if (_lastResolvedPhoto == photo && _cachedContent != null) {
      return _cachedContent!;
    }

    // Update the cache key
    _lastResolvedPhoto = photo;

    Widget content;
    if (photo != null && photo.isNotEmpty) {
      try {
        if (photo.startsWith('http')) {
          content = ClipOval(
            child: Image.network(
              photo,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitials(displayName),
            ),
          );
        } else {
          final base64Str = photo.split(',').last;
          final bytes = base64Decode(base64Str);
          content = ClipOval(
            child: Image.memory(
              bytes,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          );
        }
      } catch (_) {
        content = _buildInitials(displayName);
      }
    } else {
      content = _buildInitials(displayName);
    }

    _cachedContent = content;
    return content;
  }

  Widget _buildInitials(String name) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: widget.color,
          fontWeight: FontWeight.w800,
          fontSize: 36,
        ),
      ),
    );
  }
}



class ContributorAvatar extends StatelessWidget {
  final Member member;
  final double size;

  const ContributorAvatar({super.key, required this.member, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return AvatarSlot(
      member: member,
      size: size,
      color: textHighlightedColor,
      onLong: () {}, // no-op for long-press
    );
  }
}
