import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroSection extends StatelessWidget {
  final String? firstName;
  final String greeting;
  final String location;
  final String temperature;
  final String weatherCondition;

  const HeroSection({
    super.key,
    this.firstName,
    this.greeting = 'Welcome back to La Pirogue Mauritius',
    this.location = 'Wolmar, Flic en Flac',
    this.temperature = '28\u00b0',
    this.weatherCondition = 'Partly Cloudy',
  });

  @override
  Widget build(BuildContext context) {
    final name = firstName ?? 'Guest';
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: Icon(Icons.menu, color: Colors.white.withValues(alpha: 0.9), size: 24),
                      ),
                      const Spacer(),
                      Image.asset('assets/images/lapirogue_logo.jpg', height: 32, fit: BoxFit.contain),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Icon(Icons.notifications_outlined, color: Colors.white.withValues(alpha: 0.9), size: 24),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Good Afternoon, $name \u{1F44B}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        '$temperature $weatherCondition',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
