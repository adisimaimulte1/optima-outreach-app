import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class CustomCurrencyDropdown extends StatefulWidget {
  final String? selectedCurrency;
  final void Function(String?) onChanged;

  const CustomCurrencyDropdown({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
  });

  @override
  State<CustomCurrencyDropdown> createState() => _CustomCurrencyDropdownState();
}

class _CustomCurrencyDropdownState extends State<CustomCurrencyDropdown> {
  double _scale = 1.0;

  final List<Map<String, dynamic>> _currencies = [
    {"label": "Lei", "symbol": "lei", "icon": Icons.money},
    {"label": "Euro", "symbol": "€", "icon": Icons.euro},
    {"label": "USD", "symbol": "\$", "icon": Icons.attach_money},
  ];

  @override
  void initState() {
    super.initState();
    screenScaleNotifier.addListener(_handleScaleChange);
  }

  @override
  void dispose() {
    screenScaleNotifier.removeListener(_handleScaleChange);
    super.dispose();
  }

  void _setPressed(bool isPressed) {
    setState(() {
      _scale = isPressed ? 0.9 : 1.0;
    });
  }

  void _handleScaleChange() {
    if (screenScaleNotifier.value < 1.0 && _scale != 1.0) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _showMenu() async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + box.size.height + 6,
        offset.dx + box.size.width,
        offset.dy,
      ),
      elevation: 0,
      color: Colors.transparent,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              color: inAppForegroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: textDimColor, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _currencies.map((data) {
                final isSelected = widget.selectedCurrency == data["symbol"];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, data["symbol"]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconTheme(
                          data: IconThemeData(opacity: 1.0),
                          child: Icon(
                            data["icon"],
                            size: 18,
                            color: isSelected ? textHighlightedColor : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          data["label"],
                          style: TextStyle(
                            color: isSelected ? textHighlightedColor : textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );

    if (result != null) {
      Future.delayed(const Duration(milliseconds: 50), () {
        widget.onChanged(result);
      });
    }
  }

  IconData _iconForCurrency(String? currency) {
    switch (currency) {
      case "lei":
        return Icons.money;
      case "€":
        return Icons.euro;
      case "\$":
        return Icons.attach_money;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        if (screenScaleNotifier.value == 1.0) {
          _setPressed(false);
          _showMenu();
        }
      },
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _scale),
        duration: const Duration(milliseconds: 100),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 64,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: inAppForegroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: textDimColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      _iconForCurrency(widget.selectedCurrency),
                      color: textHighlightedColor,
                      size: 18,
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
