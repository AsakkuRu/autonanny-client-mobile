import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanny_client/view_models/rating/driver_rating_details_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/driver_rating.dart';

class DriverRatingDetailsView extends StatefulWidget {
  final int driverId;
  final String? driverName;
  final String? driverPhoto;

  const DriverRatingDetailsView({
    super.key,
    required this.driverId,
    this.driverName,
    this.driverPhoto,
  });

  @override
  State<DriverRatingDetailsView> createState() => _DriverRatingDetailsViewState();
}

class _DriverRatingDetailsViewState extends State<DriverRatingDetailsView> {
  late DriverRatingDetailsVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriverRatingDetailsVM(
      context: context,
      update: setState,
      driverId: widget.driverId,
      driverName: widget.driverName,
      driverPhoto: widget.driverPhoto,
    );
    vm.loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Рейтинг водителя',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.rating == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDriverHeader(),
                        const SizedBox(height: 24),
                        _buildRatingSummary(),
                        const SizedBox(height: 24),
                        _buildReviewsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Не удалось загрузить рейтинг',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: vm.refresh,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ProfileImage(
              url: widget.driverPhoto ?? '',
              radius: 35,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.driverName ?? 'Водитель',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vm.rating!.totalReviews} ${_getReviewWord(vm.rating!.totalReviews)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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

  Widget _buildRatingSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  vm.rating!.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.star,
                  size: 40,
                  color: Color(0xFFFFA726),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final filled = index < vm.rating!.averageRating.round();
                return Icon(
                  filled ? Icons.star : Icons.star_border,
                  size: 28,
                  color: const Color(0xFFFFA726),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Средняя оценка',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (vm.rating!.reviews.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Пока нет отзывов',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Отзывы',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...vm.rating!.reviews.map((review) => _buildReviewCard(review)),
      ],
    );
  }

  Widget _buildReviewCard(DriverReview review) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ru');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: const Color(0xFFFFA726),
                    );
                  }),
                ),
                Text(
                  dateFormat.format(review.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            if (review.authorName != null) ...[
              const SizedBox(height: 8),
              Text(
                review.authorName!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (review.criteria != null && review.criteria!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: review.criteria!.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: NannyTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontSize: 11,
                      color: NannyTheme.primary,
                    ),
                  ),
                )).toList(),
              ),
            ],
            if (review.text != null && review.text!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.text!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getReviewWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'отзыв';
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) return 'отзыва';
    return 'отзывов';
  }
}
