import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:optima/globals.dart';


class Member {
  final String id;
  final String displayName;
  final String? photo;
  final String? resolvedPhoto;
  final bool isPending;

  const Member({
    required this.id,
    required this.displayName,
    this.isPending = false,
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
        dimmed: member.isPending,
      ),
    );
  }
}



class AvatarSlot extends StatefulWidget {
  final Member? member;
  final double size;
  final Color color;
  final VoidCallback onLong;
  final bool dimmed;
  final bool isCreator;

  const AvatarSlot({
    required this.member,
    required this.size,
    required this.color,
    required this.onLong,
    this.dimmed = false,
    this.isCreator = false,
    super.key,
  });

  @override
  State<AvatarSlot> createState() => _AvatarSlotState();
}

class _AvatarSlotState extends State<AvatarSlot> with TickerProviderStateMixin {
  late final AnimationController _dimController;
  late final Animation<double> _dimOpacity;

  late final AnimationController _pressController;
  late final Animation<double> _scale;
  late final Animation<double> _shake;

  late final AnimationController _popController;
  late final Animation<double> _popScale;
  late final Animation<double> _popOpacity;

  Timer? _deleteTimer;
  bool _shouldDelete = false;

  @override
  void initState() {
    super.initState();

    _dimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dimOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dimController, curve: Curves.easeInOut),
    );

    if (widget.dimmed) _dimController.value = 1.0;

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
    _shake = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.linear),
    );

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popScale = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeInBack),
    );
    _popOpacity = Tween(begin: 1.0, end: 0.0).animate(_popController);
  }

  @override
  void didUpdateWidget(covariant AvatarSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dimmed != oldWidget.dimmed) {
      widget.dimmed ? _dimController.forward() : _dimController.reverse();
    }
  }

  @override
  void dispose() {
    _dimController.dispose();
    _pressController.dispose();
    _popController.dispose();
    _deleteTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (widget.isCreator) return;

    _shouldDelete = false;
    _pressController.repeat(reverse: true);
    _deleteTimer = Timer(const Duration(milliseconds: 400), () {
      _shouldDelete = true;
      _popController.forward().whenComplete(widget.onLong);
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
          final shake = sin(_pressController.value * pi * 6) * _shake.value;
          final scale = _shouldDelete ? _popScale.value : _scale.value;
          final opacity = _shouldDelete ? _popOpacity.value : 1.0;

          return Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: shake,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: _buildAvatarContent(dashed),
      ),
    );
  }

  Widget _buildAvatarContent(bool dashed) {
    final photo = widget.member?.resolvedPhoto ?? '';
    final displayName = widget.member?.displayName ?? '';
    final content = _getCachedContent(photo, displayName);


    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dashed ? Colors.transparent : textHighlightedColor,
            border: Border.all(color: widget.color, width: dashed ? 2 : 3),
          ),
          child: ClipOval(child: content),
        ),
        FadeTransition(
          opacity: _dimOpacity,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }





  Widget? _cachedContent;
  String? _lastPhoto;

  Widget _getCachedContent(String photo, String displayName) {
    if (_lastPhoto == photo && _cachedContent != null) {
      return _cachedContent!;
    }

    _lastPhoto = photo;
    _cachedContent = photo.isNotEmpty
        ? _buildImage(photo, displayName)
        : _buildInitials(displayName);
    return _cachedContent!;
  }

  Widget _buildImage(String photo, String fallback) {
    try {
      if (photo.startsWith('http')) {
        return Image.network(
          photo,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          errorBuilder: (_, __, ___) => _buildInitials(fallback),
        );
      }

      final bytes = base64Decode(photo.split(',').last);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    } catch (_) {
      return _buildInitials(fallback);
    }
  }

  Widget _buildInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    final initials = parts.isEmpty
        ? '+'
        : parts.take(2).map((e) => e[0].toUpperCase()).join();

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: widget.color,
        ),
      ),
    );
  }
}



class ContributorAvatar extends StatelessWidget {
  final Member member;
  final double size;
  final bool showCrown;

  const ContributorAvatar({
    super.key,
    required this.member,
    this.size = 56,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AvatarSlot(
          key: ValueKey(member.id),
          member: member,
          size: size,
          color: showCrown ? textHighlightedColor : textSecondaryHighlightedColor,
          dimmed: member.isPending,
          isCreator: showCrown,
          onLong: () {}, // no-op
        ),
        if (showCrown)
          Positioned(
            top: -10,
            left: -8,
            child: Transform.rotate(
              angle: -0.5, // slight tilt in radians (~-20 degrees)
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.crown,
                  size: 30,
                  color: textHighlightedColor,
                  shadows: [
                    Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
