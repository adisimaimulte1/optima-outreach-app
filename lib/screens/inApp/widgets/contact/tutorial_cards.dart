import 'package:flutter/material.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/contact/tutorial_card_item.dart';

class TutorialCards extends StatefulWidget {
  const TutorialCards({super.key});

  @override
  _TutorialCardsState createState() => _TutorialCardsState();
}

class _TutorialCardsState extends State<TutorialCards> {
  late final PageController _pageController;
  double _currentPage = 2.0;

  final List<Map<String, dynamic>> _cards = [
    {'title': 'Getting Started', 'icon': Icons.play_circle},
    {'title': 'Event Setup', 'icon': Icons.calendar_month},
    {'title': 'Team Management', 'icon': Icons.groups},
    {'title': 'Live Assist', 'icon': Icons.headset_mic},
    {'title': 'Settings', 'icon': Icons.settings},
  ];


  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.6,
      initialPage: 2,
    );

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? _currentPage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _title('Tutorials'),
        const SizedBox(height: 30),
        SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 5,
            itemBuilder: (context, index) {
              final card = _cards[index];
              return TutorialCardItem(
                index: index,
                currentPage: _currentPage,
                title: card['title'],
                icon: card['icon'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _title(String text) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 2, width: text.length.toDouble() * 16, color: Colors.white24),
      ],
    );
  }
}
