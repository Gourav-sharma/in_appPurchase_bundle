import 'package:in_app_subscription_bundle/in_app_subscription_bundle.dart';

abstract class SampleEvent {}

class LoadSubscriptionStatus extends SampleEvent {
  final BuildContext context;
  LoadSubscriptionStatus(this.context);
}
class BuySubscriptionEvent extends SampleEvent {
  final BuildContext context;
  BuySubscriptionEvent(this.context);
}
class SaveSubscriptionDataEvent extends SampleEvent {
  final SubscriptionRequest request;
  SaveSubscriptionDataEvent(this.request);
}