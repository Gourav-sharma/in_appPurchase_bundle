import '../in_app_subscription_bundle.dart';

class InAppSubscriptionPlugin {
  // A static method to create and provide the BLoC
  static SubsBlocNew createBloc({
    required BuildContext context,
    String? checkSubscriptionApi,
    RequestType? checkSubscriptonApiRequestType,
    String? saveSubscriptionApiUrl,
    List<String>? subscriptionProductIds,
  }) {
    return SubsBlocNew(
      context: context,
      checkSubscriptionApi: checkSubscriptionApi ?? "",
      checkSubscriptonApiRequestType: checkSubscriptonApiRequestType ?? RequestType.get,
      saveSubscriptionApiUrl: saveSubscriptionApiUrl ?? "",
      subscriptionProductIds: subscriptionProductIds ?? [],
      subscriptionPlans: {
        "monthly_plan": kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(days: 30),
        "yearly_plan": kDebugMode
            ? const Duration(minutes: 30)
            : const Duration(days: 365),
      },
    );
  }
}

