import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_client/view_models/rating/driver_rating_vm.dart';

class DriverRatingView extends StatefulWidget {
  final int orderId;
  final String? driverName;
  final String? driverPhoto;

  const DriverRatingView({
    super.key,
    required this.orderId,
    this.driverName,
    this.driverPhoto,
  });

  @override
  State<DriverRatingView> createState() => _DriverRatingViewState();
}

class _DriverRatingViewState extends State<DriverRatingView> {
  late DriverRatingVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriverRatingVM(
      context: context,
      update: setState,
      orderId: widget.orderId,
      driverName: widget.driverName,
      driverPhoto: widget.driverPhoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Оцените поездку',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Фото и имя водителя
              if (widget.driverPhoto != null || widget.driverName != null) ...[
                ProfileImage(
                  url: widget.driverPhoto ?? '',
                  radius: 50,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.driverName ?? 'Водитель',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Как прошла поездка?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Звёзды рейтинга
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => vm.setRating(index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < vm.rating ? Icons.star : Icons.star_border,
                        size: 48,
                        color: index < vm.rating
                            ? const Color(0xFFFFA726)
                            : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                vm.ratingText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: vm.rating > 0 ? NannyTheme.primary : Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Критерии оценки
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Что понравилось?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.availableCriteria.map((criterion) {
                  final isSelected = vm.selectedCriteria.contains(criterion);
                  return FilterChip(
                    label: Text(criterion),
                    selected: isSelected,
                    onSelected: (_) => vm.toggleCriterion(criterion),
                    selectedColor: NannyTheme.primary.withOpacity(0.2),
                    checkmarkColor: NannyTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? NannyTheme.primary : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Текстовый отзыв
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Комментарий (необязательно)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: vm.reviewController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Расскажите подробнее о поездке...',
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
                ),
              ),
              const SizedBox(height: 32),

              // Кнопка отправки
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: vm.rating > 0 ? vm.submitRating : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NannyTheme.primary,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: vm.isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
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
              const SizedBox(height: 16),

              // Кнопка пропуска
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Пропустить',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
