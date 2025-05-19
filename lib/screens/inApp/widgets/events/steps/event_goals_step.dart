import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class EventGoalsStep extends StatefulWidget {
  final String goals;
  final ValueChanged<String> onGoalsAdded;

  const EventGoalsStep({
    super.key,
    required this.goals,
    required this.onGoalsAdded,
  });

  @override
  State<EventGoalsStep> createState() => EventGoalsStepState();
}

class EventGoalsStepState extends State<EventGoalsStep> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();

  static const int _goalCharLimit = 30;

  final List<String?> _slots = List.filled(4, null);
  int? _editingIndex;

  @override
  void initState() {
    super.initState();

    final lines = widget.goals.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    for (var i = 0; i < _slots.length && i < lines.length; i++) _slots[i] = lines[i];

    _controller = TextEditingController();
  }

  Future<bool> saveIfPendingGoal() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 150));

    final txt = _controller.text.trim();
    if (txt.isEmpty) return false;

    final idx = _editingIndex ?? _slots.indexWhere((e) => e == null);
    if (idx == -1) return false;

    setState(() {
      _slots[idx] = txt;
      _editingIndex = null;
      _controller.clear();
      _emitGoals();
    });

    return true;
  }



  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }



  void _saveCurrentText() {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    final idx = _editingIndex ?? _slots.indexWhere((e) => e == null);
    if (idx == -1) return;                       // all full
    setState(() {
      _slots[idx] = txt;
      _editingIndex = null;
      _controller.clear();
      _emitGoals();
    });
  }

  void _clearCurrentField() {

    if (_editingIndex != null) {
      setState(() {
        _slots[_editingIndex!] = null;
        _editingIndex = null;
        _controller.clear();
        _emitGoals();
      });
    } else {
      _controller.clear();
    }
  }


  void _emitGoals() {
    widget.onGoalsAdded(_slots.where((e) => e != null && e.isNotEmpty).join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _title("What goals do you have?"),
          const SizedBox(height: 16),
          _inputRow(),
          const SizedBox(height: 24),
          Expanded(
            child: _ScatteredGoalCircles(
              slots : _slots,
              onTap : (i) {
                setState(() {
                  _editingIndex = i;
                  _controller.text = _slots[i] ?? '';
                  _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
                });
              },
              onLongPress : (i) {
                setState(() {
                  _slots[i] = null;
                  if (_editingIndex == i) _editingIndex = null;
                  _emitGoals();
                });
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _title(String t) => Column(
    children: [
      Text(t, textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(height: 2, width: 280, color: Colors.white24),
    ],
  );

  Widget _inputRow() {
    return Row(
      children: [

        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: 1,
            maxLength: _goalCharLimit,
            textAlign: TextAlign.center,
            scrollController: _scrollController,
            scrollPhysics: const BouncingScrollPhysics(),
            decoration: standardInputDecoration(
              hint: "e.g. Raise awareness about...",
              fillColor: Colors.white.withOpacity(0.06),
              borderColor: Colors.white24,
            ).copyWith(counterText: ''),
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),

        _actionIcon(Icons.arrow_forward, "Save", _saveCurrentText),
        const SizedBox(width: 8),

        _actionIcon(Icons.delete_outline, "Clear", _clearCurrentField),
      ],
    );
  }

  Widget _actionIcon(IconData i, String tip, VoidCallback act) => Tooltip(
    message: tip,
    child: _PressableScaleIconButton(icon: i, onPressed: act),
  );
}



class _ScatteredGoalCircles extends StatelessWidget {
  final List<String?> slots;
  final void Function(int index) onTap;
  final void Function(int index) onLongPress;

  const _ScatteredGoalCircles({
    required this.slots,
    required this.onTap,
    required this.onLongPress,
  });

  String _wrapGoal(String raw, {int perLine = 12}) {
    final words = raw.split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    var lineLen = 0;

    for (final w in words) {
      if (lineLen + w.length > perLine) {
        buffer.write('\n');
        lineLen = 0;
      }
      buffer.write(w);
      buffer.write(' ');
      lineLen += w.length + 1;
    }
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight;

        final data = [
          Offset(w * 0.03, h * 0.001),   // circle 0
          Offset(w * 0.25, h * 0.6),   // circle 1
          Offset(w * 0.64, h * 0.5),   // circle 2
          Offset(w * 0.54, h * 0.05),   // circle 3
        ];
        final sizes = [120.0, 80.0, 100.0, 90.0];

        return Stack(
          children: List.generate(4, (i) {
            final txt = slots[i];
            final filled = txt != null && txt.isNotEmpty;
            return Positioned(
              left: data[i].dx,
              top : data[i].dy,
              child: _BouncyGoalCircle(
                onTap      : () => onTap(i),
                onLongPress: () => onLongPress(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  width: sizes[i],
                  height: sizes[i],
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color : filled ? textHighlightedColor : Colors.transparent,
                    border: Border.all(
                      color: filled ? textHighlightedColor : Colors.white24,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),

                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve : Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                    child: filled
                        ? Text(
                      _wrapGoal(txt),
                      key: const ValueKey('filled'),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color      : inAppForegroundColor,
                        fontWeight : FontWeight.bold,
                        fontSize   : 15,
                        height     : 1.15,
                      ),
                    )
                        : Icon(Icons.add,
                        key: const ValueKey('empty'),
                        size: 28,
                        color: Colors.white38),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}



class _PressableScaleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _PressableScaleIconButton({required this.icon, required this.onPressed});

  @override
  State<_PressableScaleIconButton> createState() => _PressableScaleIconButtonState();
}

class _PressableScaleIconButtonState extends State<_PressableScaleIconButton> {
  double _scale = 1.0;
  void _set(bool p) => setState(() => _scale = p ? 0.8 : 1.0);

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp  : (_) {
      _set(false);
      widget.onPressed();
    },
    onPointerCancel: (_) => _set(false),
    child: TweenAnimationBuilder(
      tween: Tween(begin: 1.0, end: _scale),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: textHighlightedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(widget.icon, size: 30, color: inAppForegroundColor),
      ),
    ),
  );
}



class _BouncyGoalCircle extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _BouncyGoalCircle({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_BouncyGoalCircle> createState() => _BouncyGoalCircleState();
}

class _BouncyGoalCircleState extends State<_BouncyGoalCircle> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() {
      _scale = pressed ? 0.85 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      onPointerCancel: (_) => _setPressed(false),
      onPointerMove: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: widget.child,
      ),
    );
  }
}

