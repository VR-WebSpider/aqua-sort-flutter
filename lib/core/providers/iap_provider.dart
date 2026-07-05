import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/core/services/iap_service.dart';

final iapServiceProvider = ChangeNotifierProvider<IapService>((ref) {
  final service = IapService();
  
  // Clean up the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
