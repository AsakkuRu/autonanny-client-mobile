import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';

class NannyMapGlobals {
  static ValueNotifier< Set<Polyline> > routes = ValueNotifier({});
  static ValueNotifier< Set<Marker> > markers = ValueNotifier({});
  
  static Stream<LatLng> get onMapTap => mapTapController.stream;
  static final StreamController<LatLng> mapTapController =
      StreamController.broadcast();
}