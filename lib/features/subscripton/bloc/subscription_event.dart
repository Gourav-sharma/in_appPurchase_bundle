
import '../../../in_app_subscription_bundle.dart';

abstract class SubscriptionEvent {}

class SubscriptionInitEvent extends SubscriptionEvent {
  final BuildContext context;

  SubscriptionInitEvent({required this.context});
}

class GetSubscriptionVerifyEvent extends SubscriptionEvent{

  final ApiResponse response;

  GetSubscriptionVerifyEvent({
    required this.response,
  });
}

class BuyProductEvent extends SubscriptionEvent{
  final BuildContext context;
  final int? selectedItem;
  final bool? restore;
  final String? productId;

  BuyProductEvent({
    required this.context,
    this.selectedItem,
    this.restore,
    this.productId,
  });
}

class PurchaseUpdateEvent extends SubscriptionEvent {
  final List<PurchaseDetails> purchases;
  PurchaseUpdateEvent(this.purchases);
}

class DowngradeOrUpgradeEvent extends SubscriptionEvent{
  final BuildContext context;
  DowngradeOrUpgradeEvent({
    required this.context
  });
}

class VerifyPurchaseEvent extends SubscriptionEvent {
  final PurchaseDetails purchaseDetails;
  List<PurchaseDetails>? purchaseDetailsList;
  final String? secretKey;
  VerifyPurchaseEvent({required this.purchaseDetails, this.purchaseDetailsList,
    this.secretKey});
}

class GetOldPurchaseEvent extends SubscriptionEvent{
  GetOldPurchaseEvent();
}

class SaveSubscriptionEvent extends SubscriptionEvent {
  final String saveSubscriptionApiUrl;
  dynamic subsRequest;
  final Completer<Map<String, dynamic>>? completer;
  SaveSubscriptionEvent({
    required this.saveSubscriptionApiUrl,
    required this.subsRequest,
    this.completer,
  });
}

class ChangeSelectedItemEvent extends SubscriptionEvent {
  final int selectedItem;
  final String? productId;
  ChangeSelectedItemEvent(this.selectedItem,{this.productId});
}