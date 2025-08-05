import '../in_app_subscription_bundle.dart';

class InAppSubscriptionPlugin {
  // A static method to create and provide the BLoC
  static SubsBlocNew createBloc({
    required BuildContext context,
    required String checkSubscriptionApi,
    required RequestType checkSubscriptonApiRequestType,
    required String saveSubscriptionApiUrl,
    required List<String> subscriptionProductIds,
  }) {
    return SubsBlocNew(
      context: context,
      checkSubscriptionApi: checkSubscriptionApi,
      checkSubscriptonApiRequestType: checkSubscriptonApiRequestType,
      saveSubscriptionApiUrl: saveSubscriptionApiUrl,
      subscriptionProductIds: subscriptionProductIds,
    );
  }
}

