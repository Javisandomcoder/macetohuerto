import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';

final notificationTapProvider = StreamProvider<String>((ref) {
  final service = NotificationService();
  final controller = StreamController<String>();

  final initial = service.consumeInitialTapPayload();
  if (initial != null) {
    controller.add(initial);
  }

  final sub =
      service.tapStream.listen(controller.add, onError: controller.addError);

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});
