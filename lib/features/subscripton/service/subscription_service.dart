import 'package:project_setup/app_utils/common_util_methods.dart';

import '../../../in_app_subscription_bundle.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

class SubscriptionService {

  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isAvailable = false;
  bool clicked = false;
  bool loader = false;
  bool? purchaseDone;
  List<PurchaseDetails> currentPurchases = [];

  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? subscription;
  late PurchaseDetails purchaseDetail;
  List<String> notFoundIds = <String>[];
  List<String> _productIds = [];


  factory SubscriptionService.getInstance() {
    return _instance;
  }

  Future<bool> init(List<String> productIds) async {
    _productIds = productIds;

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
      inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    _isAvailable = await inAppPurchase.isAvailable();
    return _isAvailable;
  }

  Future<List<ProductDetails>> loadProducts() async {
    final response = await inAppPurchase.queryProductDetails(_productIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      throw Exception("Products not found: ${response.notFoundIDs}");
    }
    return response.productDetails;
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      await inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: false, // For subscriptions, do not auto-consume
      );
    } on PlatformException catch (e) {
      if (Platform.isIOS) {
        await completePendingIosTransactions();
      }
      AppLogs.showErrorLogs('Error while making purchase: ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> checkSubscription({required RequestType apiType,String? apiUrl,}) async {
    try {
      ApiResponse response = await ApiRepository.apiCall(
        apiUrl??"",
        apiType
      );
      return response.data;
    } catch (e) {
      return {
        "status": false,
        "message": e.toString(),
      };
    }
  }

  Future<void> downgradeOrUpgrade({required BuildContext context,
    required ProductDetails newProduct,
    required List<PurchaseDetails> currentPurchases,
    required String oldProductId}) async {
    try {
      if (Platform.isAndroid) {
        final GooglePlayPurchaseDetails? oldPurchase = _getOldSubscription(
            currentPurchases, oldProductId);
        final GooglePlayPurchaseParam purchaseParam = GooglePlayPurchaseParam(
          productDetails: newProduct,
          changeSubscriptionParam: oldPurchase != null
              ? ChangeSubscriptionParam(
            oldPurchaseDetails: oldPurchase,
            replacementMode: ReplacementMode.withTimeProration,
          )
              : null,
        );
        await inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: false, // For subscriptions, do not auto-consume
        );
      } else {
        final purchaseParam = PurchaseParam(productDetails: newProduct);
        await inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: false, // For subscriptions, do not auto-consume
        );
      }
    } on PlatformException catch (e) {
      if (e.toString().contains('storekit_duplicate_product_object')) {
        AppLogs.showErrorLogs("Purchase issue: $e");
      } else {
        CommonUtilMethods.showSnackBar(
            context: context,
            message: "Purchase Failed: $e"
        );
      }
      AppLogs.showErrorLogs("Purchase issue: $e");
    }
  }

  // Handle errors during the purchase
  Future<void> handlePurchaseError({required BuildContext context,required PurchaseDetails purchaseDetails}) async {
    AppLogs.showErrorLogs('Purchase error: ${purchaseDetails.error}');
    if (Platform.isIOS) {
      inAppPurchase.completePurchase(purchaseDetails);
      completePendingOrErrorPurchase(context,purchaseDetails.error.toString(), purchaseDetail: purchaseDetails);
    }
  }

  Future<void> completePendingOrErrorPurchase(BuildContext context,String message, {PurchaseDetails? purchaseDetail}) async {
    if (message.toString().contains('storekit_duplicate_product_object')) {
      if (Platform.isIOS) {
        await inAppPurchase.completePurchase(purchaseDetail!);
        completePendingIosTransactions();
      } else {
        if (purchaseDetail != null) {
          await inAppPurchase.completePurchase(purchaseDetail);
        }
        AppLogs.showErrorLogs("Purchase issue: $message");
      }
    } else {
      if (message.toString().contains('SKErrorDomain')) {
      } else {
        AppLogs.showErrorLogs("Purchase issue: $message");
      }
      if (purchaseDetail != null) {
        await inAppPurchase.completePurchase(purchaseDetail);
      }
    }
  }

  Future<void> completePendingIosTransactions() async {
    if (Platform.isIOS) {
      final transactions = await SKPaymentQueueWrapper().transactions();

      for (final transaction in transactions) {
        if (transaction.transactionState == SKPaymentTransactionStateWrapper.purchased ||
            transaction.transactionState == SKPaymentTransactionStateWrapper.restored ||
            transaction.transactionState == SKPaymentTransactionStateWrapper.failed) {
          try {
            await SKPaymentQueueWrapper().finishTransaction(transaction);
            AppLogs.showInfoLogs("Finished pending transaction: ${transaction.transactionIdentifier}");
          } catch (e) {
            AppLogs.showErrorLogs("Failed to finish transaction: $e");
          }
        }
      }
    }
  }

  GooglePlayPurchaseDetails? _getOldSubscription(List<PurchaseDetails> pastPurchases, String oldProductId) {
    try {
      return pastPurchases.whereType<GooglePlayPurchaseDetails>().firstWhere((p) => p.productID == oldProductId);
    } catch (_) {
      AppLogs.showErrorLogs("No old subscription found matching $oldProductId");
      return null;
    }
  }


  Future<Map<String, dynamic>> selectedAndPurchasedPlan(String? id, int index) async {
    Map<String, dynamic> map = {};
    map['selectedPlanId'] = id;
    return map;
  }

  Future<ProductDetails> selectedPlan(String expiryDate, List<ProductDetails> products, int selectedItem) async {
    late ProductDetails productDetails;
    String selectedId = products[selectedItem].id;
    if (Platform.isAndroid) {
      if (expiryDate.isNotEmpty) {
        for (int i = 0; i < products.length; i++) {
          if (products[i].id == selectedId) {
            if (products[i].price != "Free" && products[i].rawPrice != 0.0) {
              productDetails = products[i];
            }
          }
        }
      }else{
        for (int i = 0; i < products.length; i++) {
          if (products[i].id == selectedId) {
            if (products[i].price == "Free" || products[i].rawPrice == 0.0) {
              productDetails = products[i];
            }
          }
        }
      }
    }else{
      productDetails = products[selectedItem];
    }

    return productDetails;
  }

  void listenToPurchaseUpdates(Function(List<PurchaseDetails>) onUpdate) {
    subscription = inAppPurchase.purchaseStream.listen(onUpdate);
  }

  void dispose() {
    subscription?.cancel();
  }


}

class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }

  @override
  void paymentQueue(SKPaymentQueueWrapper queue, SKPaymentTransactionWrapper transaction) {
    // You can add more detailed handling here if necessary
    if (transaction.transactionState == SKPaymentTransactionStateWrapper.purchased) {
      // Complete the purchase on success
    } else if (transaction.transactionState == SKPaymentTransactionStateWrapper.failed) {
      AppLogs.showErrorLogs("Transaction failed: ${transaction.transactionState} - ${transaction.error}");
      SKPaymentQueueWrapper().finishTransaction(transaction);
    }
  }
}