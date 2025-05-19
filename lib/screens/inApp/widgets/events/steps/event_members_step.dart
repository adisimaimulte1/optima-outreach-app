import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/details/member_avatar.dart';
import 'package:optima/services/cache/local_cache.dart';



class EventMembersStep extends StatefulWidget {
  final List<String> initialMembers;
  final ValueChanged<List<String>> onChanged;

  const EventMembersStep({
    super.key,
    required this.initialMembers,
    required this.onChanged,
  });

  @override
  State<EventMembersStep> createState() => EventMembersStepState();
}

class EventMembersStepState extends State<EventMembersStep> {
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

  Future<bool> addIfPendingInput() async {
    final input = _field.text.trim();
    if (input.isEmpty || _isAdding) return false;
    final before = _members.length;
    await _addMember(input);
    final after = _members.length;
    return after > before;
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
            child: AvatarSlot(
              member: null,
              size: base * 2,
              color: isFull ? Colors.white38 : textHighlightedColor,
              onLong: () {}, // optional no-op
            ),
          ));

          for (int i = 0; i < members.length && i < positions.length; i++) {
            stack.add(AnimatedAvatarSlot(
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
