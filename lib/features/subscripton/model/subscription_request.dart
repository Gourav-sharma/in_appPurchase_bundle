import '../../../in_app_subscription_bundle.dart';

/// purchaseReceipt : "string"
/// secretKey : "string"
/// subscriptionType : 1
/// deviceType : 1
/// productId : "string"

SubscriptionRequest subscriptionRequestFromJson(String str) => SubscriptionRequest.fromJson(json.decode(str));
String subscriptionRequestToJson(SubscriptionRequest data) => json.encode(data.toJson());
class SubscriptionRequest {
  SubscriptionRequest({
      String? purchaseReceipt, 
      String? secretKey, 
      int? subscriptionType, 
      int? deviceType, 
      String? productId,
      String? transactionId,}){
    _purchaseReceipt = purchaseReceipt;
    _secretKey = secretKey;
    _subscriptionType = subscriptionType;
    _deviceType = deviceType;
    _productId = productId;
    _transactionId = transactionId;
}

  SubscriptionRequest.fromJson(dynamic json) {
    _purchaseReceipt = json['purchaseReceipt'];
    _secretKey = json['secretKey'];
    _subscriptionType = json['subscriptionType'];
    _deviceType = json['deviceType'];
    _productId = json['productId'];
    _transactionId = json['transactionId'];
  }
  String? _purchaseReceipt;
  String? _secretKey;
  int? _subscriptionType;
  int? _deviceType;
  String? _productId;
  String? _transactionId;
SubscriptionRequest copyWith({  String? purchaseReceipt,
  String? secretKey,
  int? subscriptionType,
  int? deviceType,
  String? productId,
  String? transactionId,
}) => SubscriptionRequest(  purchaseReceipt: purchaseReceipt ?? _purchaseReceipt,
  secretKey: secretKey ?? _secretKey,
  subscriptionType: subscriptionType ?? _subscriptionType,
  deviceType: deviceType ?? _deviceType,
  productId: productId ?? _productId,
  transactionId: transactionId ?? _transactionId,
);
  String? get purchaseReceipt => _purchaseReceipt;
  String? get secretKey => _secretKey;
  int? get subscriptionType => _subscriptionType;
  int? get deviceType => _deviceType;
  String? get productId => _productId;
  String? get transactionId => _transactionId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['purchaseReceipt'] = _purchaseReceipt;
    map['secretKey'] = _secretKey;
    map['subscriptionType'] = _subscriptionType;
    map['deviceType'] = _deviceType;
    map['productId'] = _productId;
    map['transactionId'] = _transactionId;
    return map;
  }

  @override
  String toString() {
    return 'SubscriptionRequest{_purchaseReceipt: $_purchaseReceipt, _secretKey: $_secretKey, _subscriptionType: $_subscriptionType, _deviceType: $_deviceType, _productId: $_productId, _transactionId: $_transactionId}';
  }
}