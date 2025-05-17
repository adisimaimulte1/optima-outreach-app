import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/cache/local_cache.dart';


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


class EventMembersStep extends StatefulWidget {
  final List<String> initialMembers;
  final ValueChanged<List<String>> onChanged;

  const EventMembersStep({
    super.key,
    required this.initialMembers,
    required this.onChanged,
  });

  @override
  State<EventMembersStep> createState() => _EventMembersStepState();
}

class _EventMembersStepState extends State<EventMembersStep> {
  final TextEditingController _field = TextEditingController();

  List<Member> _members = [];
  bool _isAdding = false;

  static const int _maxMembers    = 14;
  static const int _usernameChars = 40;


  @override
  void initState() {
    super.initState();
    _initializeMembers();
  }

  Future<void> _initializeMembers() async {
    List<Member> members = widget.initialMembers
        .map((id) => Member(id: id, displayName: id))
        .toList();

    List<Member> withPhotos = [];

    for (final m in members) {
      final cachedPhoto = await LocalCache().getCachedMemberPhoto(m.id);
      withPhotos.add(m.withResolvedPhoto(cachedPhoto ?? m.photo));
    }

    if (mounted) {
      setState(() => _members = withPhotos);
    }
  }


  Future<void> _ensureSignedIn() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return;
    await auth.signInAnonymously();
  }

  Future<Member?> _fetchUser(String email) async {
    try {
      await _ensureSignedIn();

      final snap = await FirebaseFirestore.instance
          .collection('public_data')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final d = snap.docs.first.data();
      if (d['photo'] != null && d['photo'].isNotEmpty) {
        await LocalCache().cacheMemberPhoto(d['email'], d['photo']);
      }

      return Member(
        id          : d['email'],
        displayName : d['name'] ?? d['email'],
        photo   : d['photo'],
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _isAdding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firestore error: ${e.code}')),
        );
      }
      return null;
    }
  }

  Future<void> _addMember(String raw) async {
    final input = raw.trim().toLowerCase();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Prevent invalid or duplicate input
    if (input.isEmpty || _members.length >= _maxMembers) return;
    if (_members.any((m) => m.id.toLowerCase() == input)) return;

    // Prevent adding yourself
    if (currentUser != null && currentUser.email?.toLowerCase() == input) {
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: textHighlightedColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 6,
          duration: const Duration(seconds: 2),
          content: Center(
            child: Text(
              "You can't add yourself as a collaborator.",
            textAlign: TextAlign.center,
              style: TextStyle(
                color: inAppBackgroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        )
      );
      return;
    }

    setState(() => _isAdding = true);
    final fetched = await _fetchUser(input);
    if (fetched == null) {
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: textHighlightedColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 6,
            duration: const Duration(seconds: 2),
            content: Center(
              child: Text(
                'User not found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: inAppBackgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          )
      );
      return;
    }

    final cachedPhoto = await LocalCache().getCachedMemberPhoto(fetched.id);
    final member = fetched.withResolvedPhoto(cachedPhoto ?? fetched.photo);
    setState(() => _isAdding = false);

    if (member == null) {
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: textHighlightedColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 6,
            duration: const Duration(seconds: 2),
            content: Center(
              child: Text(
                'Firestore error: {e.code}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: inAppBackgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          )
      );
      return;
    }

    setState(() {
      _members.insert(0, member);
      widget.onChanged(_members.map((m) => m.id).toList());
      _field.clear();
    });
  }

  void _removeMember(int idx) {
    setState(() {
      _members.removeAt(idx);
      widget.onChanged(_members.map((m) => m.id).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _title("Invite collaborators"),
          const SizedBox(height: 12),
          _inputRow(),
          const SizedBox(height: 20),
          Expanded(
            child: AvatarRadar(members: _members, onDelete: _removeMember),
          ),
        ],
      ),
    );
  }

  Widget _title(String t) => Column(
    children: [
      Text(t,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(height: 2, width: 260, color: Colors.white24),
    ],
  );

  Widget _inputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _field,
            maxLines: 1,
            maxLength: _usernameChars,
            decoration: standardInputDecoration(
              hint: "Type a user email…",
              fillColor: Colors.white.withOpacity(0.06),
              borderColor: Colors.white24,
            ).copyWith(counterText: ''),
            style: TextStyle(color: textColor, fontSize: 17),
            onSubmitted: _addMember,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Add",
          child: _BounceButton(
            onTap : _isAdding ? null : () => _addMember(_field.text),
            icon  : Icons.person_add,
            pulse : _isAdding,
          ),
        ),
      ],
    );
  }
}


class AvatarRadar extends StatelessWidget {
  final List<Member> members;
  final void Function(int index) onDelete;

  const AvatarRadar({super.key, required this.members, required this.onDelete});

  static const int _target = 5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (_, c) {
          final w = c.maxWidth, h = c.maxHeight;
          final center = Offset(w / 2, h / 2);
          const double base = 42;
          const double spacing = 36;
          const double xOffset = 0;
          const double yOffset = 0;

          const int topCount = 5;
          const int sideCount = 4; // 👈 left/right sides

          final edgeSpacing = base * 2 - spacing;
          final width = edgeSpacing * (topCount - 1);
          final height = edgeSpacing * (sideCount - 1);
          final topLeft = center - Offset(width / 2 - xOffset, height / 2 - yOffset);

          final List<Offset> positions = [];

          for (int i = 0; i < topCount; i++) {
            positions.add(topLeft + Offset(i * edgeSpacing, 0));
          }
          for (int i = 1; i <= sideCount - 2; i++) {
            positions.add(topLeft + Offset(width, i * edgeSpacing));
          }
          for (int i = topCount - 1; i >= 0; i--) {
            positions.add(topLeft + Offset(i * edgeSpacing, height));
          }
          for (int i = sideCount - 2; i >= 1; i--) {
            positions.add(topLeft + Offset(0, i * edgeSpacing));
          }



          final List<Widget> stack = [];


          final isFull = members.length >= 14;

          stack.add(Positioned(
            left: center.dx - base,
            top: center.dy - base,
            child: _AvatarSlot(
              member: null,
              size: base * 2,
              color: isFull ? Colors.white38 : textHighlightedColor,
              onLong: () {}, // optional no-op
            ),
          ));

          for (int i = 0; i < members.length && i < positions.length; i++) {
            stack.add(_AnimatedAvatarSlot(
              key: ValueKey('${members[i].id}-${members[i].resolvedPhoto ?? ''}'),
              member: members[i],
              targetOffset: positions[i] - Offset(base, base),
              centerOffset: Offset(center.dx - base, center.dy - base),
              size: base * 2,
              color: _colorFor(i),
              onLong: () => onDelete(i),
              delay: Duration(milliseconds: 100 + i * 60),
            ));
          }

          return Stack(children: stack);
        },
    );
  }

  Color _colorFor(int i) {
    var colors = [
      textHighlightedColor,
    ];
    return colors[i % colors.length];
  }
}

class _AnimatedAvatarSlot extends StatelessWidget {
  final Member member;
  final Offset targetOffset;
  final Offset centerOffset;
  final double size;
  final Color color;
  final VoidCallback onLong;
  final Duration delay;

  const _AnimatedAvatarSlot({
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
      child: _AvatarSlot(
        member: member,
        size: size,
        color: color,
        onLong: onLong,
      ),
    );
  }
}

class _AvatarSlot extends StatefulWidget {
  final Member? member;
  final double size;
  final Color color;
  final VoidCallback onLong;

  const _AvatarSlot({
    required this.member,
    required this.size,
    required this.color,
    required this.onLong,
    super.key,
  });

  @override
  State<_AvatarSlot> createState() => _AvatarSlotState();
}

class _AvatarSlotState extends State<_AvatarSlot> with TickerProviderStateMixin {
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



class _BounceButton extends StatefulWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final bool pulse;
  const _BounceButton({required this.onTap, required this.icon, this.pulse = false});

  @override
  State<_BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<_BounceButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.85),
      onPointerUp: (_) {
        setState(() => _scale = 1);
        widget.onTap?.call();
      },
      onPointerCancel: (_) => setState(() => _scale = 1),
      child: TweenAnimationBuilder(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: textHighlightedColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: Icon(widget.icon, key: ValueKey('icon'), color: inAppForegroundColor),
          ),
        ),
      ),
    );
  }
}
