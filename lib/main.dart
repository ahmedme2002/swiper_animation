import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: SwipePOC()),
  );
}

class SwipePOC extends StatefulWidget {
  const SwipePOC({super.key});

  @override
  State<SwipePOC> createState() => _SwipePOCState();
}

class _SwipePOCState extends State<SwipePOC>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _visible = false;

  late final AnimationController _sheetController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _showCard() async {
    setState(() => _visible = true);
    await _sheetController.forward(from: 0);
  }

  Future<void> _hideCard() async {
    await _sheetController.reverse();
    if (!mounted) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final sheetHeight = h * 0.89;

    return Scaffold(
      appBar: AppBar(title: const Text('flutter_card_swiper • POC')),
      body: Stack(
        children: [
          const Center(
            child: Text(
              'This is the screen below\n(e.g. camera)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),

          if (_visible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: sheetHeight,
              child: SlideTransition(
                position: _slide,
                child: _SwipeSheet(
                  controller: _swiperController,
                  onCloseRequested: _hideCard,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCard,
        child: const Icon(Icons.unfold_more_double_rounded),
      ),
    );
  }
}

class _SwipeSheet extends StatelessWidget {
  const _SwipeSheet({required this.controller, required this.onCloseRequested});

  final CardSwiperController controller;
  final VoidCallback onCloseRequested;

  Widget _buildCard(double horizontalPercentage, double verticalPercentage) {
    bool isSwipingLeft = horizontalPercentage < -0.1;
    bool isSwipingRight = horizontalPercentage > 0.1;

    double overlayOpacity = 0.0;
    Color overlayColor = Colors.transparent;
    IconData? overlayIcon;

    if (isSwipingLeft) {
      overlayOpacity = (horizontalPercentage.abs() * 2).clamp(0.0, 0.8);
      overlayColor = Colors.green;
      overlayIcon = Icons.favorite;
    } else if (isSwipingRight) {
      overlayOpacity = (horizontalPercentage.abs() * 2).clamp(0.0, 0.8);
      overlayColor = Colors.red;
      overlayIcon = Icons.block;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Swipe me',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '← Favorite (green)   |   Block (red) →\nSwipe down to close',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.style,
                    size: 80,
                    color: Colors.blue.shade400,
                  ),
                ),
              ),
            ],
          ),

          if (overlayOpacity > 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: overlayColor.withOpacity(overlayOpacity),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Icon(overlayIcon, color: Colors.white, size: 80),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: CardSwiper(
            controller: controller,
            cardsCount: 1,
            numberOfCardsDisplayed: 1,
            isLoop: false,
            padding: EdgeInsets.zero,
            backCardOffset: Offset.zero,
            allowedSwipeDirection: const AllowedSwipeDirection.only(
              left: true,
              right: true,
              down: true,
              up: false,
            ),
            cardBuilder: (context, index, hPct, vPct) =>
                _buildCard(hPct.toDouble(), vPct.toDouble()),
            onSwipe: (previousIndex, currentIndex, direction) {
              switch (direction) {
                case CardSwiperDirection.left:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to favorites ❤️'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  break;
                case CardSwiperDirection.right:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product blocked 🚫'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  break;
                case CardSwiperDirection.bottom:
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Closed')));
                  onCloseRequested();
                  break;
                default:
                  break;
              }

              if (direction == CardSwiperDirection.left ||
                  direction == CardSwiperDirection.right) {
                Future.delayed(
                  const Duration(milliseconds: 150),
                  onCloseRequested,
                );
              }

              return true;
            },
          ),
        ),
      ),
    );
  }
}
