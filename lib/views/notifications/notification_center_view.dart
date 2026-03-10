import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/notifications/notification_center_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/notification_item.dart';

/// B-014 TASK-B14: Центр уведомлений (клиент)
class NotificationCenterView extends StatefulWidget {
  const NotificationCenterView({super.key});

  @override
  State<NotificationCenterView> createState() => _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<NotificationCenterView> {
  late NotificationCenterVM vm;

  @override
  void initState() {
    super.initState();
    vm = NotificationCenterVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Уведомления',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            if (vm.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${vm.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (vm.unreadCount > 0)
            TextButton(
              onPressed: vm.markAllAsRead,
              child: Text('Прочитать все', style: TextStyle(color: NannyTheme.primary, fontSize: 13)),
            ),
        ],
      ),
      body: FutureLoader(
        future: vm.loadRequest,
        completeView: (ctx, _) => Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.refresh,
                child: vm.filteredNotifications.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.filteredNotifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildCard(vm.filteredNotifications[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: vm.filters.map((f) {
            final isSelected = vm.selectedFilter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f['label']!),
                selected: isSelected,
                onSelected: (_) => vm.setFilter(f['key']!),
                selectedColor: NannyTheme.primary.withOpacity(0.15),
                checkmarkColor: NannyTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? NannyTheme.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCard(NotificationItem item) {
    return GestureDetector(
      onTap: () => vm.markAsRead(item.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : NannyTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRead ? Colors.grey.shade200 : NannyTheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(item.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: NannyTheme.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.body, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Text(_formatDate(item.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    final data = _iconForType(type);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: data.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(data.$1, color: data.$2, size: 20),
    );
  }

  (IconData, Color) _iconForType(String type) {
    switch (type) {
      case 'order': return (Icons.directions_car, Colors.blue);
      case 'payment': return (Icons.payments, Colors.green);
      case 'referral': return (Icons.card_giftcard, Colors.purple);
      case 'system': return (Icons.info_outline, Colors.orange);
      default: return (Icons.notifications, NannyTheme.primary);
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Нет уведомлений', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays < 7) return '${diff.inDays} д назад';
    return '${date.day}.${date.month}.${date.year}';
  }
}
