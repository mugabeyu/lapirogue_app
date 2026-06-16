import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/content_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 0;
  String? _category;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final config = await ContentService().getPage('feedback-config');
      if (config != null && config.metadata != null) {
        final raw = config.metadata;
        if (raw is Map && raw['categories'] is List) {
          _categories = (raw['categories'] as List).map((e) => e.toString()).toList();
        }
      }
      if (_categories.isEmpty) {
        final distinct = await SupabaseService.client
            .from('guest_feedback')
            .select('category')
            .limit(100);
        final unique = distinct.map((e) => e['category']?.toString() ?? '').where((s) => s.isNotEmpty).toSet().toList();
        if (unique.isNotEmpty) {
          _categories = unique;
        }
      }
    } catch (_) {}
    if (_categories.isEmpty) {
      _categories = ['General', 'Room', 'Food & Beverage', 'Activities', 'Staff', 'Facilities'];
    }
    if (mounted) {
      setState(() {
        _category = _categories.isNotEmpty ? _categories.first : null;
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final guestId = await SupabaseService.getCurrentGuestId();
      if (guestId == null) throw Exception('Guest not found');

      await SupabaseService.client.from('guest_feedback').insert({
        'guest_id': guestId,
        'rating': _rating.toInt(),
        'category': _category ?? 'General',
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: AppTheme.accentGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How would you rate your experience?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? AppTheme.accentOrange : AppTheme.textTertiary,
                      size: 40,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _isLoadingCategories
                  ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _category == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _category = category);
                          },
                          selectedColor: AppTheme.primary.withValues(alpha: 0.1),
                          checkmarkColor: AppTheme.primary,
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24),
              const Text('Your Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tell us about your experience...',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter your feedback';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
