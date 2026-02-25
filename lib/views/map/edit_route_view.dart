import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/map/edit_route_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';

class EditRouteView extends StatefulWidget {
  final int orderId;
  final List<AddressData> currentAddresses;

  const EditRouteView({
    super.key,
    required this.orderId,
    required this.currentAddresses,
  });

  @override
  State<EditRouteView> createState() => _EditRouteViewState();
}

class _EditRouteViewState extends State<EditRouteView> {
  late EditRouteVM vm;

  @override
  void initState() {
    super.initState();
    vm = EditRouteVM(
      context: context,
      update: setState,
      orderId: widget.orderId,
      initialAddresses: widget.currentAddresses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Изменить маршрут',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (vm.hasChanges)
            TextButton(
              onPressed: vm.resetChanges,
              child: const Text('Сбросить'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Текущий маршрут',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...vm.addresses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final address = entry.value;
                  return _buildAddressCard(index, address);
                }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: vm.addAddress,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Добавить адрес'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (vm.priceChange != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Изменение стоимости',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vm.priceChange! > 0
                                    ? '+${vm.priceChange!.toStringAsFixed(0)} ₽'
                                    : '${vm.priceChange!.toStringAsFixed(0)} ₽',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: vm.priceChange! > 0
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.hasChanges && !vm.isSaving ? vm.saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NannyTheme.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: vm.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Сохранить изменения',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(int index, AddressData address) {
    final isFirst = index == 0;
    final isLast = index == vm.addresses.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                isFirst ? Icons.circle : Icons.location_on,
                size: isFirst ? 12 : 20,
                color: isFirst ? NannyTheme.primary : Colors.red,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () => vm.editAddress(index),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFirst ? 'Откуда' : (isLast ? 'Куда' : 'Остановка ${index}'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address.address,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isFirst && !isLast)
            IconButton(
              onPressed: () => vm.removeAddress(index),
              icon: const Icon(Icons.close, color: Colors.red),
              iconSize: 20,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
