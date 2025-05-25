import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/services/sessions/session_service.dart';
import 'package:optima/screens/inApp/widgets/settings/buttons/text_button.dart';

class SessionManagementDialog {
  static String _formatDateTime(DateTime time) {
    final date = "${_monthName(time.month)} ${time.day}";
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$date, $hour:$minute";
  }

  static String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  static Future<void> show(BuildContext context) async {
    final sessions = await SessionService().getSessions();

    popupStackCount.value++;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: inAppForegroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Active Sessions",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 420,
          height: 150,
          child: sessions.isEmpty
              ? Center(
            child: Text(
              "No active sessions found.",
              style: TextStyle(color: textColor),
              textAlign: TextAlign.center,
            ),
          )
              : ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (_, index) {
              final session = sessions[index];
              final Timestamp last = session['lastActive'];
              final formattedTime = _formatDateTime(
                DateTime.fromMillisecondsSinceEpoch(last.millisecondsSinceEpoch),
              );
              final isCurrent = session['isCurrent'];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? inAppForegroundColor : Colors.transparent,
                  border: Border.all(
                    color: isCurrent ? textHighlightedColor : Colors.white70,
                    width: 1.4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session['device'],
                            style: TextStyle(
                              color: isCurrent ? textColor : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Last active: $formattedTime",
                            style: TextStyle(
                              color: isCurrent ? textColor : Colors.white54,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (isCurrent)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "This device",
                                style: TextStyle(
                                  color: textHighlightedColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isCurrent)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          onPressed: () async {
                            await SessionService().deleteSession(session['id']);
                            Navigator.pop(context);
                            show(context);
                          },
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                            splashFactory: NoSplash.splashFactory,
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          if (sessions.length > 1)
            TextButtonWithoutIcon(
              label: "Log Out Others",
              onPressed: () async {
                await SessionService().deleteAllOtherSessions();
                Navigator.pop(context);
                show(context);
              },
              backgroundColor: Colors.red,
              foregroundColor: inAppForegroundColor,
              fontSize: 17,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          TextButtonWithoutIcon(
            label: "Close",
            onPressed: () => Navigator.pop(context),
            foregroundColor: Colors.white70,
            fontSize: 17,
            borderColor: Colors.white70,
            borderWidth: 1.2,
          ),
        ],
      ),
    ).whenComplete(() => popupStackCount.value--);
  }
}