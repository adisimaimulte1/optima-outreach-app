import 'package:flutter/material.dart';
import 'package:optima/screens/inApp/widgets/settings/bouncy_tap.dart';
import 'package:optima/screens/inApp/widgets/settings/dialogs/watch_ad_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:optima/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpgradePlanDialog {
  static void show(BuildContext context, ValueNotifier<String> selectedPlan) {
    popupStackCount.value++;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => ValueListenableBuilder<String>(
        valueListenable: selectedPlan,
        builder: (context, currentPlan, _) {
          return AlertDialog(
            backgroundColor: inAppForegroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.only(top: 24),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Column(
              children: [
                Icon(Icons.workspace_premium, size: 48, color: textHighlightedColor),
                const SizedBox(height: 12),
                Text(
                  "Your Plan",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlanCard(
                      context,
                      "free",
                      currentPlan,
                      "Free",
                      "Forever",
                      [
                        "Limited Jamie access",
                        "Earn credits via ads",
                        "Basic AI tools",
                      ],
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final safeContext = Navigator.of(context, rootNavigator: true).context;
                          Navigator.of(context, rootNavigator: true).pop();
                          await Future.delayed(const Duration(milliseconds: 250));
                          await WatchAdDialog.showRewardedAdWithUid(safeContext, user.uid);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      context,
                      "starter",
                      currentPlan,
                      "Starter",
                      "\$1 One-Time",
                      [
                        "Instant 20 credits",
                        "No subscription",
                        "Great for quick access",
                      ],
                      link: "",
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      context,
                      "pro",
                      currentPlan,
                      "Pro",
                      "\$30 / mo",
                      [
                        "20 credits every day",
                        "Unlimited Jamie usage",
                        "Priority features & support",
                      ],
                      link: "",
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

          );
        },
      ),
    ).whenComplete(() => popupStackCount.value--);
  }

  static Widget _buildPlanCard(
      BuildContext context,
      String planId,
      String currentPlan,
      String title,
      String price,
      List<String> benefits, {
        String? link,
        VoidCallback? onTap,
      }) {
    final bool isSelected = planId == currentPlan;

    return BouncyTap(
      onTap: () async {
        if (!isSelected || planId == "free") {
          if (onTap != null) {
            onTap();
          } else if (link != null && link.isNotEmpty) {
            await launchUrl(Uri.parse(link));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? textHighlightedColor : Colors.white38,
            width: isSelected ? 2.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: textHighlightedColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            )
          ]
              : [],
          color: isSelected ? inAppForegroundColor.withOpacity(0.95) : Colors.white10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? textHighlightedColor : textColor,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: textHighlightedColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Your Plan",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: inAppForegroundColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 12),
            ...benefits.map((b) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: textHighlightedColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(color: textColor, fontSize: 14.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}