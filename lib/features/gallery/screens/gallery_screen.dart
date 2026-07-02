import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final List<_GalleryImage> _images = [
    _GalleryImage('Hotel Exterior', 'Beautiful beachfront resort', Icons.image),
    _GalleryImage('Swimming Pool', 'Infinity pool with ocean view', Icons.image),
    _GalleryImage('Beach', 'Private white sand beach', Icons.image),
    _GalleryImage('Restaurant', 'Fine dining experience', Icons.image),
    _GalleryImage('Spa', 'Luxury spa treatments', Icons.image),
    _GalleryImage('Sunset View', 'Breathtaking sunset views', Icons.image),
    _GalleryImage('Garden', 'Tropical garden', Icons.image),
    _GalleryImage('Suite Room', 'Premium suite interior', Icons.image),
    _GalleryImage('Beach Bar', 'Sunset cocktails', Icons.image),
    _GalleryImage('Pool Villa', 'Private pool villa', Icons.image),
    _GalleryImage('Wedding Venue', 'Beachfront wedding setup', Icons.image),
    _GalleryImage('Fitness Center', 'Modern gym equipment', Icons.image),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: AppColors.oceanBlue,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final image = _images[index];
          return GestureDetector(
            onTap: () => _showFullscreen(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(image.icon, size: 40, color: AppColors.oceanBlue.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        image.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullscreen(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) => _FullscreenGallery(
          images: _images,
          initialIndex: index,
        ),
      ),
    );
  }
}

class _GalleryImage {
  final String title;
  final String subtitle;
  final IconData icon;
  _GalleryImage(this.title, this.subtitle, this.icon);
}

class _FullscreenGallery extends StatefulWidget {
  final List<_GalleryImage> images;
  final int initialIndex;

  const _FullscreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final image = widget.images[index];
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Icon(image.icon, size: 100, color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(image.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(image.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
