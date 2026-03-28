import 'package:flutter/material.dart';
import 'package:nanny_client/views/pages/graph.dart';

class ContractsView extends StatelessWidget {
  const ContractsView({
    super.key,
    this.persistState = false,
    this.initialContractId,
    this.openInitialContractDetails = false,
  });

  final bool persistState;
  final int? initialContractId;
  final bool openInitialContractDetails;

  @override
  Widget build(BuildContext context) {
    return GraphView(
      persistState: persistState,
      initialScheduleId: initialContractId,
      openInitialScheduleDetails: openInitialContractDetails,
    );
  }
}
