import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_subscription_bundle/in_app_subscription_bundle.dart';
import 'package:in_app_subscription_bundle/in_app_subscription_bundle_platform_interface.dart';
import 'package:in_app_subscription_bundle/in_app_subscription_bundle_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInAppSubscriptionBundlePlatform
    with MockPlatformInterfaceMixin
    implements InAppSubscriptionBundlePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final InAppSubscriptionBundlePlatform initialPlatform = InAppSubscriptionBundlePlatform.instance;

  test('$MethodChannelInAppSubscriptionBundle is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInAppSubscriptionBundle>());
  });

  test('getPlatformVersion', () async {
    InAppSubscriptionBundle inAppSubscriptionBundlePlugin = InAppSubscriptionBundle();
    MockInAppSubscriptionBundlePlatform fakePlatform = MockInAppSubscriptionBundlePlatform();
    InAppSubscriptionBundlePlatform.instance = fakePlatform;

    expect(await inAppSubscriptionBundlePlugin.getPlatformVersion(), '42');
  });
}
