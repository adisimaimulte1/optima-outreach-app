import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class TutorialCards extends StatefulWidget {
  const TutorialCards({super.key});

  @override
  _TutorialCardsState createState() => _TutorialCardsState();
}

class _TutorialCardsState extends State<TutorialCards> {
  late final PageController _pageController;
  double _currentPage = 2.0;

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
              final double distance = (_currentPage - index).abs();
              final double scale = 1 - (0.3 * distance).clamp(0.0, 0.3);

              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: inAppForegroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.help_outline, size: 40, color: textHighlightedColor),
                      const SizedBox(height: 10),
                      Text(
                        'Card $index',
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Description for card $index.',
                        style: TextStyle(color: textDimColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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

class TutorialCardItem extends StatelessWidget {
  final int index;
  final double cardWidth;
  final double cardSpacing;
  final double screenWidth;
  final int pageIndex;

  const TutorialCardItem({
    super.key,
    required this.index,
    required this.cardWidth,
    required this.cardSpacing,
    required this.screenWidth,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final double distance = (pageIndex - index).abs().toDouble();
    final double t = (distance).clamp(0.0, 1.0);
    final double scale = 1.0 - 0.3 * t;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.symmetric(horizontal: cardSpacing / 2),
        decoration: BoxDecoration(
          color: inAppForegroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 40, color: textHighlightedColor),
            const SizedBox(height: 10),
            Text(
              'Card $index',
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              'Description for card $index.',
              style: TextStyle(color: textDimColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
