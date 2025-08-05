import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'in_app_subscription_bundle_method_channel.dart';

abstract class InAppSubscriptionBundlePlatform extends PlatformInterface {
  /// Constructs a InAppSubscriptionBundlePlatform.
  InAppSubscriptionBundlePlatform() : super(token: _token);

  static final Object _token = Object();

  static InAppSubscriptionBundlePlatform _instance = MethodChannelInAppSubscriptionBundle();

  /// The default instance of [InAppSubscriptionBundlePlatform] to use.
  ///
  /// Defaults to [MethodChannelInAppSubscriptionBundle].
  static InAppSubscriptionBundlePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [InAppSubscriptionBundlePlatform] when
  /// they register themselves.
  static set instance(InAppSubscriptionBundlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
