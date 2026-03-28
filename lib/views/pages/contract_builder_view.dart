import 'package:flutter/material.dart';
import 'package:nanny_client/views/pages/graph_create.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';

class ContractBuilderView extends StatelessWidget {
  const ContractBuilderView({
    super.key,
    this.contract,
  });

  final Schedule? contract;

  @override
  Widget build(BuildContext context) {
    return GraphCreate(schedule: contract);
  }
}
