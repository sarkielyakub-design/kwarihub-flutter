import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  static const Color primaryBlue = Color(0xFF0D5CC7);
  static const Color darkBlue = Color(0xFF102F4F);

  // ==========================================================
  // ONBOARDING DATA
  // ==========================================================

  final List<_OnboardingData> _pages = const [
    // ========================================================
    // PAGE 1 - MAN
    // ========================================================

    _OnboardingData(
      title: 'Discover Amazing',
      highlightedTitle: 'Textiles',
      description:
          'Find beautiful quality textiles from trusted sellers across the marketplace.',
      image: 'assets/images/kaftan_man.png',
      icon: Icons.shopping_bag_rounded,
    ),

    // ========================================================
    // PAGE 2 - WOMAN
    // ========================================================

    _OnboardingData(
      title: 'Shop With',
      highlightedTitle: 'Confidence',
      description:
          'Explore thousands of fabrics, compare products and buy from verified vendors.',
      image: 'assets/images/kaftan_women.png',
      icon: Icons.verified_user_rounded,
    ),

    // ========================================================
    // PAGE 3 - ATAMFA
    // ========================================================

    _OnboardingData(
      title: 'Your Textile',
      highlightedTitle: 'Marketplace',
      description:
          'Everything you need for fashion, tailoring and textile business in one place.',
      image: 'assets/images/Kaftan_atamfa.png',
      icon: Icons.storefront_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ==========================================================
  // NEXT
  // ==========================================================

  void _next() {
    if (_currentPage == _pages.length - 1) {
      context.go('/login');
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // ==========================================================
  // SKIP
  // ==========================================================

  void _skip() {
    context.go('/login');
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // TOP BAR
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                4,
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/kwarihub_logo.png',
                    width: 105,
                    height: 45,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: darkBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        color: darkBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // ONBOARDING PAGES
            // ==================================================

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _pages[index],
                    primaryBlue: primaryBlue,
                    darkBlue: darkBlue,
                  );
                },
              ),
            ),

            // ==================================================
            // BOTTOM CONTROLS
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                6,
                24,
                20,
              ),
              child: Column(
                children: [
                  // ==================================================
                  // PAGE INDICATORS
                  // ==================================================

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) {
                        final bool active = index == _currentPage;

                        return AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 250,
                          ),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? primaryBlue
                                : const Color(0xFFD5E2F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // NEXT / GET STARTED BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 21,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // LOGIN
                  // ==================================================

                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: darkBlue,
                    ),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        color: darkBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ONBOARDING DATA
// ============================================================

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.highlightedTitle,
    required this.description,
    required this.image,
    required this.icon,
  });

  final String title;
  final String highlightedTitle;
  final String description;
  final String image;
  final IconData icon;
}

// ============================================================
// ONBOARDING PAGE
// ============================================================

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.primaryBlue,
    required this.darkBlue,
  });

  final _OnboardingData data;
  final Color primaryBlue;
  final Color darkBlue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        24,
        10,
        24,
        4,
      ),
      child: Column(
        children: [
          // ==================================================
          // FULL IMAGE
          // ==================================================

          SizedBox(
            height: 370,
            width: double.infinity,
            child: _TextileVisual(
              image: data.image,
              icon: data.icon,
              primaryBlue: primaryBlue,
            ),
          ),

          const SizedBox(height: 22),

          // ==================================================
          // TITLE
          // ==================================================

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: darkBlue,
            ),
          ),

          // ==================================================
          // HIGHLIGHTED TITLE
          // ==================================================

          Text(
            data.highlightedTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: primaryBlue,
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // DESCRIPTION
          // ==================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FULL KAFTAN IMAGE VISUAL
// ============================================================

class _TextileVisual extends StatelessWidget {
  const _TextileVisual({
    required this.image,
    required this.icon,
    required this.primaryBlue,
  });

  final String image;
  final IconData icon;
  final Color primaryBlue;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================
          // FULL IMAGE
          // ==================================================

          Image.asset(
            image,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // ==================================================
          // VERY LIGHT BOTTOM GRADIENT
          // ==================================================

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),

          // ==================================================
          // CENTER SHOP / STATUS ICON
          // ==================================================

          Align(
            alignment: Alignment.center,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 35,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}