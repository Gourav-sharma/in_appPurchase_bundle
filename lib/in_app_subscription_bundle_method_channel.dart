import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'in_app_subscription_bundle_platform_interface.dart';

/// An implementation of [InAppSubscriptionBundlePlatform] that uses method channels.
class MethodChannelInAppSubscriptionBundle extends InAppSubscriptionBundlePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('in_app_subscription_bundle');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
