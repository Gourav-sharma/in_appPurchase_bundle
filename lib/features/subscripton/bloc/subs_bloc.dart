
import 'package:http/http.dart' as http;

import '../../../in_app_subscription_bundle.dart';

class SubsBlocNew extends Bloc<SubscriptionEvent, SubscriptionState> {

  final SubscriptionService service = SubscriptionService();
  final BuildContext context;
  final String checkSubscriptionApi;
  final RequestType checkSubscriptonApiRequestType;
  final String saveSubscriptionApiUrl;
  final List<String> subscriptionProductIds;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final InAppPurchase inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? subscription;
  late  PurchaseDetails purchaseDetail;
  List<String> notFoundIds = <String>[];

  /// Product IDs with durations (testing + production)
  final Map<String, Duration> subscriptionPlans;

  SubsBlocNew({required this.context,
     this.checkSubscriptionApi = "",
     this.checkSubscriptonApiRequestType = RequestType.get,
     this.saveSubscriptionApiUrl = "",
      required this.subscriptionProductIds,
      required this.subscriptionPlans
  }) : super(SubscriptionState()) {
    on<SubscriptionInitEvent>(initEvent);
    on<VerifyPurchaseEvent>(verifyPurchaseEvent);
    on<BuyProductEvent>(buyProductEvent);
    on<PurchaseUpdateEvent>(_onPurchaseUpdate);
    on<GetOldPurchaseEvent>(getOldPurchaseEvent);
    on<DowngradeOrUpgradeEvent>(downgradeOrUpgradeEvent);
    on<SaveSubscriptionEvent>(saveSubscriptionEvent);
    on<ChangeSelectedItemEvent>(_changeSelectedItem);
  }

 Future<void> initEvent(SubscriptionInitEvent event, Emitter<SubscriptionState> emit) async {

    AppLogs.showInfoLogs("init event calling::::::::::::::::: $subscriptionProductIds");
   //check products availability
   final isAvailable = await service.init(subscriptionProductIds);
   if (!isAvailable) {
     AppLogs.showErrorLogs('In-App Purchases is not available on this platform.');
     return;
   }
   for (int i = 0; i < subscriptionProductIds.length; i++) {
     String product = subscriptionProductIds[i];
     AppLogs.showInfoLogs("product id ::$product");

   }

   //load and sort products
   final subscriptionProducts = await service.loadProducts();
   service.listenToPurchaseUpdates((purchases) {
     if (!isClosed) {
       add(PurchaseUpdateEvent(purchases));
     }
   });
   List<ProductDetails>? products = subscriptionProducts;
   if(Platform.isIOS){products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));}
   AppLogs.showInfoLogs("products length: ${products.length}");
   for (int i = 0; i < products.length; i++) {
     AppLogs.showInfoLogs("product id ::${products[i].id}");
     AppLogs.showInfoLogs("product title ::${products[i].title}");
     AppLogs.showInfoLogs("product price ::${products[i].price}");
     AppLogs.showInfoLogs("product rawPrice ::${products[i].rawPrice}");
   }
   // save products to state
   List<SubscriptionProducts> subscriptionItems = products.map((product) {
     return SubscriptionProducts(
         id: product.id,
         title: product.title,
         description: product.description,
         price: product.price,
         rawPrice: product.rawPrice,
         currencyCode: product.currencyCode,
         currencySymbol: product.currencySymbol,
         selectedItem: state.selectedItem,
         subscriptionType: 0,
         isSubscribed: false
     );
   }).toList();
   SubscriptionProductsResponse productsResponse = SubscriptionProductsResponse(
     products: subscriptionItems,
   );
   emit(state.copyWith(
     products: products,
     subscriptionProducts: productsResponse.products,
     selectedProductId: productsResponse.products?[state.selectedItem].id,
   ));

    //  Map<String, dynamic>? checkSubscriptionData ;
    // if(checkSubscriptionApi.isNotEmpty) {
    //   checkSubscriptionData = await service
    //       .checkSubscription(
    //       apiType: checkSubscriptonApiRequestType,
    //       apiUrl: checkSubscriptionApi
    //   );
    // }

    //check subscription
   // if(checkSubscriptionApi.isNotEmpty){
   //   final Map<String, dynamic>? checkSubscriptionData = await service.checkSubscription(
   //       apiType: checkSubscriptonApiRequestType,
   //       apiUrl: checkSubscriptionApi
   //   );
   //
   //   if(checkSubscriptionData != null){
   //     isActive = checkSubscriptionData["data"]["isActive"] == true;
   //   }
   //
   //   if (isActive) {
   //     AppLogs.showInfoLogs("✅ Active subscription");
   //     emit(state.copyWith( isSubscribed: true,
   //       subscriptionType: checkSubscriptionData?["data"]["subscriptionType"]?? 1,
   //       subsExpiryDate: checkSubscriptionData?["data"]["expiryDate"]?? "",));
   //     int? matchedIndex;
   //
   //     for (int i = 0; i < products.length; i++) {
   //       for (int j = 0; j < subscriptionProductIds.length; j++) {
   //         if (products[i].id == subscriptionProductIds[j]) {
   //           // Prefer paid subscriptions if available
   //           if (products[i].price != "Free" && products[i].rawPrice != 0.0) {
   //             matchedIndex = i;
   //             break; // Found paid version
   //           } else {
   //             matchedIndex ??= i;
   //           }
   //         }
   //       }
   //     }
   //     if (matchedIndex != null) {
   //       emit(state.copyWith(selectedItem: matchedIndex));
   //     }
   //   } else {
   //     AppLogs.showErrorLogs("❌ Inactive subscription");
   //
   //     for (int i = 0; i < products.length; i++) {
   //       for (int j = 0; j < subscriptionProductIds.length; j++) {
   //         if (products[i].price != "Free" &&
   //             products[i].rawPrice != 0.0) {
   //           AppLogs.showInfoLogs("products.length: ${products.length}");
   //           AppLogs.showInfoLogs("subscriptionProductIds.length: ${subscriptionProductIds.length}");
   //           AppLogs.showInfoLogs("products[i].id: ${products[i].id}");
   //           AppLogs.showInfoLogs("products[i].price: ${products[i].price}");
   //           AppLogs.showInfoLogs("products[i].rawPrice: ${products[i].rawPrice}");
   //           if(products[i].id == subscriptionProductIds[0]){
   //
   //           }
   //           break;
   //         }
   //
   //       }
   //     }
   //   }
   // }

    emit(state.copyWith(loader: false));

    //get old purchase from android
    add(GetOldPurchaseEvent());

  }

 Future<void> getOldPurchaseEvent(GetOldPurchaseEvent event,Emitter<SubscriptionState> emit) async {

    List<PurchaseDetails> pastPurchases = [];
    if(Platform.isAndroid){
      final InAppPurchaseAndroidPlatformAddition androidAddition =
      inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      final QueryPurchaseDetailsResponse response =
      await androidAddition.queryPastPurchases();

      if (response.error != null) {
        AppLogs.showErrorLogs("Android past purchase error: ${response.error}");
        return;
      }
      pastPurchases = response.pastPurchases;
    }else if (Platform.isIOS) {
      pastPurchases = await getIosPastPurchases();
    }

    if (pastPurchases.isEmpty) {
      AppLogs.showInfoLogs("No past purchases found");
      emit(state.copyWith(isSubscribed: false));
      return;
    }

    for (final purchase in pastPurchases) {
      final purchasedProductId = purchase.productID;

      int purchaseTime = 0;
      if (Platform.isAndroid) {
        final data = jsonDecode(
            (purchase as GooglePlayPurchaseDetails).billingClientPurchase.originalJson);
        purchaseTime = data['purchaseTime'] ?? 0;
      } else if (Platform.isIOS) {
        purchaseTime = int.tryParse(purchase.transactionDate ?? "0") ?? 0;
      }

      final duration =
          subscriptionPlans[purchasedProductId] ?? const Duration(days: 30);

      final expiryDate =
      DateTime.fromMillisecondsSinceEpoch(purchaseTime).add(duration);
      final isExpired = DateTime.now().isAfter(expiryDate);
      final isSubscribed = !isExpired;

      if (purchase.status == PurchaseStatus.purchased) {
        final paidIndex =
        state.products.indexWhere((p) => p.id == purchasedProductId);

        emit(state.copyWith(
          isSubscribed: isSubscribed,
          purchases: pastPurchases,
          selectedProductId: purchasedProductId,
          pastSubscriptionId: purchasedProductId,
          selectedItem: isSubscribed ? paidIndex : 0,
        ));

        AppLogs.showInfoLogs(
          "${isSubscribed ? "✅ Active" : "❌ Expired"} | productId: $purchasedProductId",
        );

        break; // handle first valid purchase only
      }
    }

 }


  // buy first time subscription
  Future<void> buyProductEvent(BuyProductEvent event,Emitter<SubscriptionState> emit) async {

    emit(state.copyWith(isClicked: true,loader: true));
    if(event.restore==true){
      if(state.isSubscribed == false){
        await service.inAppPurchase.restorePurchases();
      }else{
        CommonUtilMethods.showSnackBar(
            context: context,
            message: "You are already subscribed."
        );
      }
    }else{
      if(state.isSubscribed == true){
        add(DowngradeOrUpgradeEvent(context: context));
      }else {
        ProductDetails purchaseProduct = await service.selectedPlan(
            state.subsExpiryDate,
            state.products, state.selectedItem,
            subscriptionProductIds, state.purchases);
        await service.buyProduct(
            purchaseProduct
        );
      }
    }

  }

  Future<void> downgradeOrUpgradeEvent(DowngradeOrUpgradeEvent event,Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isClicked: true,loader: true));
    final oldProductId = state.pastSubscriptionId;
    AppLogs.showInfoLogs("oldProductId: $oldProductId");
    AppLogs.showInfoLogs("state.selectedItem: ${state.selectedItem}");
    AppLogs.showInfoLogs("state.selectedProductId: ${state.selectedProductId}");
    if(state.selectedProductId==oldProductId){
      if(context.mounted){
        CommonUtilMethods.showSnackBar(
            context: event.context,
            message: "You are already subscribed to this plan."
        );
        emit(state.copyWith(loader: false));
      }
      return;
    }
    ProductDetails purchaseProduct = await service.selectedPlan(state.subsExpiryDate,state.products,state.selectedItem,
        subscriptionProductIds,state.purchases);
    AppLogs.showInfoLogs("purchaseProduct: ${purchaseProduct.price}");

    if(context.mounted){
      await service.downgradeOrUpgrade(
        context: event.context,
        newProduct: purchaseProduct,
        currentPurchases: state.purchases,
        oldProductId: oldProductId,
      );
    }

  }

  Future<void> _onPurchaseUpdate(PurchaseUpdateEvent event, Emitter<SubscriptionState> emit) async {

    for (var purchase in event.purchases) {
      AppLogs.showInfoLogs("purchase.status: ${purchase.status}");
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
          if (purchase.pendingCompletePurchase) {
            await service.inAppPurchase.completePurchase(purchase);
            if (state.isClicked==true) {
              add(VerifyPurchaseEvent(purchaseDetails: purchase,
              purchaseDetailsList: event.purchases,));
              emit(state.copyWith(
                pastSubscriptionId: purchase.productID,
                isSubscribed: true
              ));
            }
          }
          break;
        case PurchaseStatus.restored:
          if (purchase.pendingCompletePurchase) {
            await service.inAppPurchase.completePurchase(purchase);
          }
          if (state.isClicked==true) {
            add(VerifyPurchaseEvent(purchaseDetails: purchase,
                purchaseDetailsList: event.purchases));
            emit(state.copyWith(
                pastSubscriptionId: purchase.productID,
                isSubscribed: true
            ));
          }
          break;
        case PurchaseStatus.error:
          await service.handlePurchaseError(context: context, purchaseDetails: purchase);
          if(context.mounted) {
            emit(state.copyWith(loader: false, isClicked: false));
          }
          break;
        case PurchaseStatus.canceled:
          if (Platform.isIOS) {
            await service.inAppPurchase.completePurchase(purchase);
          }
          if(context.mounted) {
            emit(state.copyWith(loader: false, isClicked: false));
          }
          break;
        }
    }

  }

  PurchaseDetails sortAppleTransactionsDescending(List<PurchaseDetails> purchases) {
    purchases.sort((a, b) {
      final aDate = _parseDate(a.transactionDate);
      final bDate = _parseDate(b.transactionDate);

      return bDate.compareTo(aDate); // Descending order
    }
    );
    return purchases.first;
  }

  DateTime _parseDate(String? timestamp) {
    if (timestamp == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(int.tryParse(timestamp) ?? 0);
  }

  Future<void> verifyPurchaseEvent(VerifyPurchaseEvent event, Emitter<SubscriptionState> emit) async {
    try {
      AppLogs.showInfoLogs(
          "purchase receipt::::::::${Platform.isAndroid ? event.purchaseDetails.verificationData.serverVerificationData : event.purchaseDetails.verificationData.localVerificationData}");
      if (event.purchaseDetails.status == PurchaseStatus.purchased || event.purchaseDetails.status == PurchaseStatus.restored) {
        emit(state.copyWith(isClicked: false,
        purchases: event.purchaseDetailsList,
        isSubscribed:true));
        SubscriptionRequest subsRequest = SubscriptionRequest(
          productId: event.purchaseDetails.productID,
          purchaseReceipt: Platform.isAndroid
              ? event.purchaseDetails.verificationData.serverVerificationData
              : event.purchaseDetails.verificationData.localVerificationData,
          secretKey: Platform.isIOS ? event.secretKey : "",
          deviceType: Platform.isAndroid ? 1 : 2,
          subscriptionType: state.subscriptionType ?? 1,
          transactionId: event.purchaseDetails.purchaseID ?? "",);

        add(SaveSubscriptionEvent(saveSubscriptionApiUrl:saveSubscriptionApiUrl,subsRequest: subsRequest ));
      }

    } catch (e, s) {
      AppLogs.showErrorLogs("purchase error::::::::$e stack trace::::$s");
    }
  }

  Future<void> saveSubscriptionEvent(SaveSubscriptionEvent event, Emitter<SubscriptionState> emit,) async {

    try {
       await ApiRepository.apiCall(
          event.saveSubscriptionApiUrl,
          RequestType.post,
          data: event.subsRequest
      );
       if(context.mounted) {
         Navigator.of(context).pop();
       }
    } catch (e) {
      AppLogs.showErrorLogs(e.toString());
    }

  }

  Future<void> _changeSelectedItem(ChangeSelectedItemEvent event, Emitter<SubscriptionState> emit)async {
    emit(state.copyWith(
        selectedItem: event.selectedItem,
        selectedProductId: event.productId??"",
        currentSubscriptionId: state.subscriptionProducts[event.selectedItem].id
    ));
  }

  String removeAfterMonthlyOrYearly(String input) {
    // Check if the input contains "Monthly" or "Yearly"
    if (input.toLowerCase().contains('monthly')) {
      int monthlyIndex = input.toLowerCase().indexOf('monthly');
      return input.substring(0, monthlyIndex + 'Monthly'.length);
    } else if (input.toLowerCase().contains('yearly')) {
      int yearlyIndex = input.toLowerCase().indexOf('yearly');
      return input.substring(0, yearlyIndex + 'Yearly'.length);
    }

    // If neither "Monthly" nor "Yearly" is found, return the original input
    return input;
  }

  Future<String?> _getReceiptData() async {
    final receiptData = await SKReceiptManager.retrieveReceiptData();
    return receiptData; // base64-encoded string
  }

  Future<Map<String, dynamic>> verifyReceipt(String receiptData, {bool isSandbox = true}) async {
    final url = isSandbox
        ? 'https://sandbox.itunes.apple.com/verifyReceipt'
        : 'https://buy.itunes.apple.com/verifyReceipt';

    final payload = jsonEncode({
      "receipt-data": receiptData,
      "password": "YOUR_SHARED_SECRET", // App-Specific Shared Secret from App Store Connect
      "exclude-old-transactions": true
    });

    final response = await http.post(
      Uri.parse(url),
      body: payload,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to verify receipt: ${response.body}");
    }
  }

  Future<List<PurchaseDetails>> getIosPastPurchases() async {
    // Step 1: Get local transactions
    final transactions = await SKPaymentQueueWrapper().transactions();
    final List<PurchaseDetails> purchases = [];

    for (final txn in transactions) {
      purchases.add(PurchaseDetails(
        purchaseID: txn.transactionIdentifier,
        productID: txn.payment.productIdentifier,
        transactionDate: txn.transactionTimeStamp != null
            ? (txn.transactionTimeStamp! * 1000).toInt().toString()
            : "0",
        status: PurchaseStatus.purchased,
        verificationData: PurchaseVerificationData(
          localVerificationData: "",
          serverVerificationData: "",
          source: "appstore",
        ),
      ));
    }

    // Step 2: Get receipt data from device
    final receiptData = await _getReceiptData();
    if (receiptData != null) {
      final receipt = await verifyReceipt(receiptData, isSandbox: true);

      // Parse expiry info from receipt
      final latestReceiptInfo = receipt['latest_receipt_info'] as List<dynamic>? ?? [];
      for (final item in latestReceiptInfo) {
        final productId = item['product_id'];
        final expiresDateMs = int.tryParse(item['expires_date_ms'] ?? "0") ?? 0;

        final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresDateMs);
        final isExpired = DateTime.now().isAfter(expiryDate);

        AppLogs.showInfoLogs(
          "iOS Receipt: $productId expires at $expiryDate | Active: ${!isExpired}",
        );
      }
    }

    return purchases;
  }

  Future<Map<String, dynamic>> checkActiveSubscription() async {
    try {
      final transactions = await SKPaymentQueueWrapper().transactions();

      for (final txn in transactions) {
        final productId = txn.payment.productIdentifier;
        final purchaseDateMs =
            int.tryParse(txn.transactionTimeStamp.toString()) ?? 0;

        // Assume fixed duration per product (like Android logic)
        final duration =
            subscriptionPlans[productId] ?? const Duration(days: 30);

        final expiryDate =
        DateTime.fromMillisecondsSinceEpoch(purchaseDateMs).add(duration);
        final isExpired = DateTime.now().isAfter(expiryDate);

        if (!isExpired) {
          return {
            "isSubscribed": true,
            "productId": productId,
            "expiryDate": expiryDate,
          };
        }
      }
      return {"isSubscribed": false};
    } catch (e) {
      AppLogs.showErrorLogs("iOS subscription check failed: $e");
      return {"isSubscribed": false};
    }
  }

  // Future<bool> checkActiveSubscription() async {
  //   final receipt = await _getReceiptData();
  //   if (receipt == null) return false;
  //
  //   final result = await verifyReceipt(receipt, isSandbox: true); // switch to false in production
  //
  //   if (result["status"] != 0) return false;
  //
  //   final latest = result["latest_receipt_info"]?.last;
  //   if (latest == null) return false;
  //
  //   final expiresMs = int.tryParse(latest["expires_date_ms"] ?? "0") ?? 0;
  //   final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresMs);
  //
  //   final isCancelled = latest["cancellation_date"] != null;
  //
  //   return !isCancelled && DateTime.now().isBefore(expiryDate);
  // }

  @override
  Future<void> close() {
    subscription?.cancel();
    return super.close();
  }

  Future<void> dispose() {
    subscription?.cancel();
    return super.close();
  }

}