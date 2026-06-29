// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/models/activity.dart';
import '../../../core/theme/app_theme.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final activities = await ActivityService().getAvailableActivities();
    if (mounted) {
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities & Tours'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildActivitiesList(),
    );
  }

  Widget _buildActivitiesList() {
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 64, color: AppTheme.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No activities available', style: TextStyle(color: AppTheme.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _ActivityCard(activity: activity);
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                activity.imagePath!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.duration} min',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Rs ${activity.price}',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    if (activity.meetingPoint != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          activity.meetingPoint!,
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
