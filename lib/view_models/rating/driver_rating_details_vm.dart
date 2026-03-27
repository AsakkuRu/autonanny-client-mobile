import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/driver_rating.dart';

class DriverRatingDetailsVM extends ViewModelBase {
  DriverRatingDetailsVM({
    required super.context,
    required super.update,
    required this.driverId,
    this.driverName,
    this.driverPhoto,
  });

  final int driverId;
  final String? driverName;
  final String? driverPhoto;

  DriverRating? rating;
  bool isLoading = true;

  @override
  Future<bool> loadPage() async {
    update(() => isLoading = true);

    final result = await NannyOrdersApi.getDriverRating(driverId);
    if (result.success && result.response != null) {
      rating = result.response;
    } else {
      rating = null;
    }

    update(() => isLoading = false);
    return true;
  }

  Future<void> refresh() async {
    await loadPage();
  }
}
