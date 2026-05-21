import 'package:doomscrolling_guard/core/themes/app_colors.dart';
import 'package:doomscrolling_guard/features/onboarding/screens/permission_guide_screen.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Scroll dengan Lebih Sadar',
      'body':
          'Doomscroll Guard membantu Anda melihat kebiasaan digital dengan tenang, bukan menghakimi.',
    },
    {
      'title': 'Pengingat Lembut',
      'body':
          'Saat Anda terlalu lama melihat layar, kami akan mengingatkan Anda untuk beristirahat sejenak.',
    },
    {
      'title': 'Anda yang Mengatur',
      'body':
          'Sesuaikan batas dan pilih aplikasi yang ingin Anda pantau agar tetap nyaman.',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Done - navigate to permission screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionGuideScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.eco_rounded,
                              size: 100,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index]['title']!,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['body']!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryAccent
                              : AppColors.primaryAccent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Mulai'
                          : 'Selanjutnya',
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
