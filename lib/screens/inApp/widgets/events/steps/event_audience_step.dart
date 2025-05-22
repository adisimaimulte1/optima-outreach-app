import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/beforeApp/widgets/buttons/bouncy_button.dart';
import 'package:optima/screens/inApp/widgets/events/currency_dropdown.dart';

class EventAudienceStep extends StatefulWidget {
  final List<String> selectedTags;
  final bool isPublic;
  final bool isPaid;
  final double? price;
  final String? currency;

  final Function({
  required List<String> audience,
  required bool isPublic,
  required bool isPaid,
  required double? price,
  required String? currency,
  }) onChanged;


  const EventAudienceStep({
    super.key,
    required this.selectedTags,
    required this.isPublic,
    required this.isPaid,
    required this.price,
    required this.onChanged,
    required this.currency,
  });

  @override
  State<EventAudienceStep> createState() => EventAudienceStepState();
}

class EventAudienceStepState extends State<EventAudienceStep> {
  String? selectedCurrency;
  final GlobalKey<_CustomTextFieldState> _customFieldKey = GlobalKey<_CustomTextFieldState>();

  void _notifyChange({
    List<String>? audience,
    bool? isPublic,
    bool? isPaid,
    double? price,
    String? currency,
  }) {
    final isNowPaid = isPaid ?? widget.isPaid;

    if (isNowPaid && (currency ?? selectedCurrency) == null) {
      selectedCurrency = "lei";
    }
    widget.onChanged(
      audience: audience ?? widget.selectedTags,
      isPublic: isPublic ?? widget.isPublic,
      isPaid: isPaid ?? widget.isPaid,
      price: price ?? widget.price,
      currency: currency ?? selectedCurrency,
    );
  }


  void _togglePaidUI() {
    _customFieldKey.currentState?.togglePaidView();
  }

  @override
  void initState() {
    super.initState();
    selectedCurrency = widget.currency;
  }

  Future<bool> saveIfPendingAudienceInput() async {
    return await _customFieldKey.currentState?.saveIfPendingInput() ?? false;
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Column
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HighlightedTitle("Who's this for?"),
                                const SizedBox(height: 21),
                                AudienceOptions(
                                  selectedTags: widget.selectedTags,
                                  onChanged: (audience) =>
                                      _notifyChange(audience: audience),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Divider
                      Container(width: 1, color: Colors.white24),

                      // Right Column
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            children: [
                              const HighlightedTitle("Details"),
                              const SizedBox(height: 16),
                              VisibilityEntry(
                                isPublic: widget.isPublic,
                                isPaid: widget.isPaid,
                                onChanged: (public, paid) =>
                                    _notifyChange(isPublic: public, isPaid: paid),
                                onTogglePaidUI: _togglePaidUI, // 👈 passed here
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            CustomTextField(
              key: _customFieldKey,
              selectedTags: widget.selectedTags,
              isPaid: widget.isPaid,
              price: widget.price,
              currency: selectedCurrency,
              onCurrencyChanged: (val) {
                setState(() => selectedCurrency = val);
                _notifyChange(currency: val);
              },
              onChanged: _notifyChange,
            ),
          ],
        ),
      ),
    );
  }
}




class HighlightedTitle extends StatelessWidget {
  final String text;
  const HighlightedTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 2, width: 180, color: Colors.white24),
      ],
    );
  }
}


class AudienceOptions extends StatelessWidget {
  final List<String> selectedTags;
  final Function(List<String>) onChanged;

  const AudienceOptions({
    required this.selectedTags,
    required this.onChanged,
  });

  static const options = {
    "Volunteers": Icons.volunteer_activism,
    "Everyone": Icons.public,
    "Students": Icons.school,
    "Experts": Icons.business_center,
    "Custom": Icons.edit,
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: options.entries.map((entry) {
          final isCustom = entry.key == "Custom" &&
              selectedTags.any((e) => e.startsWith("Custom:"));
          final isSelected = selectedTags.contains(entry.key) || isCustom;

          return GestureDetector(
            onTap: () {
              final updated = List<String>.from(selectedTags);

              if (isSelected) {
                // Deselect: remove "Custom" and all "Custom:..."
                updated.remove(entry.key);
                updated.removeWhere((e) => e.startsWith("Custom:"));
              } else {
                // Select: first remove "Custom:" if exists
                updated.removeWhere((e) => e.startsWith("Custom:"));

                // Only add plain "Custom" if it's not already in (avoid duplicates)
                if (entry.key == "Custom") {
                  updated.add("Custom");
                } else {
                  updated.add(entry.key);
                }
              }

              onChanged(updated);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(maxWidth: 140),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? textHighlightedColor : inAppForegroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? textHighlightedColor : textDimColor,
                  width: isSelected ? 0 : 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(entry.value,
                      color: isSelected ? inAppForegroundColor : textColor,
                      size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      entry.key,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? inAppForegroundColor : textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class VisibilityEntry extends StatelessWidget {
  final bool isPublic;
  final bool isPaid;
  final Function(bool isPublic, bool isPaid) onChanged;
  final VoidCallback onTogglePaidUI;

  const VisibilityEntry({
    super.key,
    required this.isPublic,
    required this.isPaid,
    required this.onChanged,
    required this.onTogglePaidUI,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniToggle("Public", isPublic, () => onChanged(true, isPaid)),
          _miniToggle("Private", !isPublic, () => onChanged(false, isPaid)),
          const SizedBox(height: 20),
          _miniToggle("Free", !isPaid, () => onChanged(isPublic, false)),
          _miniToggle("Paid", isPaid, () {
            onChanged(isPublic, true);
            onTogglePaidUI(); // 👈 also toggle Paid UI
          }),
        ],
      ),
    );
  }

  Widget _miniToggle(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: BouncyButton(
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: const BoxConstraints(minWidth: 100, maxWidth: 110),
          decoration: BoxDecoration(
            color: selected ? textHighlightedColor : inAppForegroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? textHighlightedColor : textDimColor,
              width: selected ? 0 : 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? inAppForegroundColor : textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class CustomTextField extends StatefulWidget {
  final List<String> selectedTags;
  final bool isPaid;
  final double? price;
  final Function({
  List<String>? audience,
  bool? isPublic,
  bool? isPaid,
  double? price,
  }) onChanged;

  final String? currency;
  final void Function(String?) onCurrencyChanged;

  const CustomTextField({
    super.key,
    required this.selectedTags,
    required this.isPaid,
    required this.price,
    required this.currency,
    required this.onChanged,
    required this.onCurrencyChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  String _customText = '';
  String _paidText = '';
  bool _forceCustomView = false;
  bool _forcePaidView = false;

  @override
  void initState() {
    super.initState();

    _customText = widget.selectedTags.firstWhere(
          (e) => e.startsWith("Custom:"),
      orElse: () => '',
    ).replaceFirst("Custom:", '');

    _paidText = widget.price?.toString() ?? '';
    _forcePaidView = widget.isPaid;

    _controller = TextEditingController(
      text: widget.isPaid ? _paidText : _customText,
    );

    _controller.addListener(_handleChange);
  }

  Future<bool> saveIfPendingInput() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));

    final val = _controller.text.trim();
    if (val.isEmpty) return false;

    if (_showCustomInput()) {
      final updated = List<String>.from(widget.selectedTags)
        ..removeWhere((e) => e.startsWith("Custom:"))
        ..add("Custom:$val");

      widget.onChanged(audience: updated);
      return true;
    }

    if (_showPaidInput()) {
      final parsed = double.tryParse(val);
      if (parsed == null || parsed <= 0) return false;

      widget.onChanged(price: parsed);
      return true;
    }

    return false;
  }


  void _handleChange() {
    final val = _controller.text;
    if (_showCustomInput()) {
      _customText = val;
      final updated = List<String>.from(widget.selectedTags)
        ..removeWhere((e) => e.startsWith("Custom:"))
        ..add("Custom:$val");
      widget.onChanged(audience: updated);
    } else {
      _paidText = val;
      final parsed = double.tryParse(val);
      widget.onChanged(price: parsed);
    }
  }

  bool _showCustomInput() {
    return widget.selectedTags.any(
          (e) => e == "Custom" || e.startsWith("Custom:"),
    ) && _forceCustomView;
  }

  bool _showPaidInput() {
    return widget.isPaid && !_showCustomInput() && _forcePaidView;
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasCustomSelected = oldWidget.selectedTags.any(
          (e) => e == "Custom" || e.startsWith("Custom:"),
    );
    final isCustomSelected = widget.selectedTags.any(
          (e) => e == "Custom" || e.startsWith("Custom:"),
    );

    // Switching into Custom
    if (isCustomSelected && !_forceCustomView && !wasCustomSelected) {
      _customText = widget.selectedTags.firstWhere(
            (e) => e.startsWith("Custom:"),
        orElse: () => '',
      ).replaceFirst("Custom:", '');
      _forceCustomView = true;
      _forcePaidView = false;
      _updateControllerText(_customText);
    }

    // Update Custom text
    if (isCustomSelected) {
      _customText = widget.selectedTags.firstWhere(
            (e) => e.startsWith("Custom:"),
        orElse: () => '',
      ).replaceFirst("Custom:", '');

      if (_forceCustomView) {
        _updateControllerText(_customText);
      }
    }

    // Exiting Custom
    if (!isCustomSelected && _forceCustomView) {
      _customText = '';
      _forceCustomView = false;

      if (widget.isPaid) {
        _forcePaidView = true;
        _updateControllerText(_paidText); // 👈 restore paid input
      } else {
        _updateControllerText('');
      }
    }

    // Exiting Paid
    if (!widget.isPaid && _forcePaidView) {
      _forcePaidView = false;
      _paidText = '';

      if (isCustomSelected) {
        _forceCustomView = true;
        _updateControllerText(_customText);
      } else {
        _updateControllerText('');
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(price: null);
      });
    }
  }

  void _updateControllerText(String text) {
    _controller.removeListener(_handleChange);
    _controller.text = text;
    _controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomSelected = widget.selectedTags.any(
          (e) => e == "Custom" || e.startsWith("Custom:"),
    );
    final shouldEnable = widget.isPaid || isCustomSelected;
    final showCustomInput = _showCustomInput();
    final showPaidInput = _showPaidInput();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: _controller,
            enabled: shouldEnable,
            keyboardType: showCustomInput
                ? TextInputType.text
                : const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (isCustomSelected) _switchToCustomView();
              FocusScope.of(context).unfocus();
            },
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: !shouldEnable
                  ? "Select Custom or Paid first"
                  : showCustomInput
                  ? "Custom audience"
                  : "Entry fee",
              hintStyle: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w400,
              ),
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16).copyWith(left: showPaidInput ? 64 : 16),
              counterText: '',
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24, width: 1.2),
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24, width: 1.2),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24, width: 1.6),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          // Currency dropdown if Paid view
          if (showPaidInput)
            Positioned(
              left: 12,
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Future.delayed(
                    const Duration(milliseconds: 50),
                        () => widget.onCurrencyChanged(widget.currency), // optional if you want refresh
                  );
                },
                child: CustomCurrencyDropdown(
                  selectedCurrency: widget.currency,
                  onChanged: widget.onCurrencyChanged,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void togglePaidView() {
    setState(() {
      if (_forcePaidView) {
        _switchToCustomView();
      } else {
        _forcePaidView = true;
        _forceCustomView = false;
        _updateControllerText(_paidText);
      }
    });
  }

  void _switchToCustomView() {
    final isCustomSelected = widget.selectedTags.any(
          (e) => e == "Custom" || e.startsWith("Custom:"),
    );
    if (!isCustomSelected) return;

    final updated = List<String>.from(widget.selectedTags)
      ..removeWhere((e) => e.startsWith("Custom:"))
      ..add("Custom: $_customText");

    widget.onChanged(audience: updated);
    setState(() {
      _forceCustomView = true;
      _forcePaidView = false;
      _updateControllerText(_customText);
    });
  }
}
