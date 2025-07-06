import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/dashboard/buttons/settings_button.dart';

class CreditsLeftCard extends StatelessWidget {
  const CreditsLeftCard({super.key});

  @override
  Widget build(BuildContext context) {
    final double cardHeight = MediaQuery.of(context).size.width * 0.17;
    final double scale = (MediaQuery.of(context).size.width / 390).clamp(0.5, 1.0);

    return ValueListenableBuilder<int>(
      valueListenable: creditNotifier,
      builder: (context, currentCredits, _) {
        return ValueListenableBuilder<double>(
          valueListenable: subCreditNotifier,
          builder: (context, subCreditValue, _) {
            final double progress = (subCreditValue % 1).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      height: cardHeight,
                      padding: EdgeInsets.symmetric(horizontal: 13 * scale, vertical: 12 * scale),
                      decoration: BoxDecoration(
                        color: inAppForegroundColor,
                        borderRadius: BorderRadius.circular(20 * scale),
                        border: Border.all(color: textDimColor, width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            currentCredits == 0 ? Icons.credit_card_off : Icons.credit_score,
                            color: currentCredits == 0 ? Colors.red : textHighlightedColor,
                            size: 34 * scale,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$currentCredits Credits",
                                  style: TextStyle(
                                    fontSize: 18 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: textDimColor.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(textHighlightedColor),
                                  minHeight: 8 * scale,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SettingsButton(size: cardHeight),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
