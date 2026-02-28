import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../services/storage_service.dart';
import '../../shared/widgets/loading_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.threed_rotation_rounded,
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
    ),
    _OnboardingPage(
      icon: Icons.water_drop_rounded,
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
    ),
    _OnboardingPage(
      icon: Icons.phone_android_rounded,
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
    ),
  ];

  void _finish() async {
    final storage = StorageService();
    await storage.init();
    await storage.setOnboardingDone();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Indicator
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: const WormEffect(
                dotColor: Colors.grey,
                activeDotColor: AppColors.primary,
                dotHeight: 10,
                dotWidth: 10,
              ),
            ),
            const SizedBox(height: 24),

            // Next / Get Started
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: LoadingButton(
                label:
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: AppColors.primary),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
