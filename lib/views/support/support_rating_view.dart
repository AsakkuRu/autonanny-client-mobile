import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/support/support_rating_vm.dart';
import 'package:nanny_client/widgets/rate_widget.dart';
import 'package:nanny_components/nanny_components.dart';

class SupportRatingView extends StatefulWidget {
  final int ticketId;
  final VoidCallback? onSubmitted;

  const SupportRatingView({
    super.key,
    required this.ticketId,
    this.onSubmitted,
  });

  @override
  State<SupportRatingView> createState() => _SupportRatingViewState();
}

class _SupportRatingViewState extends State<SupportRatingView> {
  late SupportRatingVM vm;

  @override
  void initState() {
    super.initState();
    vm = SupportRatingVM(
      context: context,
      update: setState,
      ticketId: widget.ticketId,
      onSubmitted: widget.onSubmitted,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Оценка поддержки',
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: vm.skip,
            child: Text(
              'Пропустить',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: NannyTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                size: 36,
                color: NannyTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Оцените качество поддержки',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ваш отзыв помогает нам становиться лучше',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildStarLabels(),
            const SizedBox(height: 8),
            RateWidget(
              tapCallback: vm.selectRating,
              selected: vm.rating - 1,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: vm.commentController,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Оставьте комментарий (необязательно)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: NannyTheme.primary),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.canSubmit ? vm.submitRating : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NannyTheme.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: vm.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Отправить оценку',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Плохо', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        Text('Отлично', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
