import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/contact/tutorial_card_item.dart';




class TutorialCards extends StatefulWidget {
  const TutorialCards({super.key});

  @override
  _TutorialCardsState createState() => _TutorialCardsState();
}

class _TutorialCardsState extends State<TutorialCards> {
  late final PageController _pageController;
  bool _isMinimized = false;

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

    _pageController = PageController(viewportFraction: 0.6, initialPage: currentTutorialPage.round());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PageRegistry.register(ScreenType.contact, _pageController);
    });

    _pageController.addListener(() {
      setState(() {
        currentTutorialPage = _pageController.page ?? currentTutorialPage;
      });
    });

    screenScaleNotifier.addListener(_handleScaleChange);
    _isMinimized = screenScaleNotifier.value < 0.99;
  }

  void _handleScaleChange() {
    final minimized = screenScaleNotifier.value < 0.99;
    if (_isMinimized != minimized && mounted) {
      setState(() => _isMinimized = minimized);

      if (minimized) {
        final currentPage = _pageController.page ?? currentTutorialPage;
        _pageController.animateToPage(
          currentPage.round(),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    PageRegistry.unregister(ScreenType.contact);
    screenScaleNotifier.removeListener(_handleScaleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _title('Tutorials'),
        const SizedBox(height: 30),
        SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          child: IgnorePointer(
            ignoring: _isMinimized,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return TutorialCardItem(
                  key: tutorialCardKeys[index],
                  index: index,
                  currentPage: currentTutorialPage,
                  title: card['title'],
                  icon: card['icon'],
                );
              },
            ),
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
        Container(
          height: 2,
          width: text.length.toDouble() * 16,
          color: Colors.white24,
        ),
      ],
    );
  }
}
