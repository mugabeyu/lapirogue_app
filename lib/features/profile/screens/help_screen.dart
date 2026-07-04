import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    {'q': 'How do I make a reservation?', 'a': 'Go to the Home screen and tap "Book a Room" or navigate to Rooms from the menu. Select your dates and choose an available room.'},
    {'q': 'Can I cancel my reservation?', 'a': 'Yes, you can cancel your reservation from the Reservations screen. Free cancellation is available up to 48 hours before check-in.'},
    {'q': 'How do I pre-book activities?', 'a': 'Once you have an active reservation, visit the Activities, Dining, or Spa sections to book services in advance.'},
    {'q': 'When does room service become available?', 'a': 'Room Service, Laundry, and Housekeeping become available after you check in at the hotel.'},
    {'q': 'How do I reset my password?', 'a': 'On the login screen, tap "Forgot Password" and follow the instructions sent to your email.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          ..._faqs.map((faq) => _buildFaqCard(faq['q']!, faq['a']!)),
        ],
      ),
    );
  }

  Widget _buildFaqCard(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        leading: const Icon(Icons.help_outline, color: AppColors.darkNavy),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
          ),
        ],
      ),
    );
  }
}