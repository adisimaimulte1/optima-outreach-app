import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/details/member_avatar.dart';

class CollaboratorsBlock extends StatelessWidget {
  final List<Member> members;

  const CollaboratorsBlock({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    final hasMembers = members.isNotEmpty;
    final needsScroll = members.length > 6;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: textColor.withOpacity(0.3),
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56,
                child: hasMembers
                    ? needsScroll
                    ? ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.02, 0.98, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return ContributorAvatar(
                        member: members[index],
                        size: 55,
                      );
                    },
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: members
                      .map((member) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ContributorAvatar(member: member, size: 55),
                  ))
                      .toList(),
                )
                    : Center(
                  child: Text(
                    "No collaborators yet.",
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
