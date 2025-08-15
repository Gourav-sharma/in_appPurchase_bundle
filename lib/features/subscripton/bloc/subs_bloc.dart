
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


  SubsBlocNew({required this.context,
     this.checkSubscriptionApi = "",
     this.checkSubscriptonApiRequestType = RequestType.get,
     this.saveSubscriptionApiUrl = "",
      required this.subscriptionProductIds,
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
   for (int i = 0; i < products.length; i++) {
     AppLogs.showInfoLogs("product id ::${products[i].id}");
     AppLogs.showInfoLogs("product title ::${products[i].title}");
     AppLogs.showInfoLogs("product description ::${products[i].description}");
     AppLogs.showInfoLogs("product price ::${products[i].price}");
     AppLogs.showInfoLogs("product rawPrice ::${products[i].rawPrice}");
     AppLogs.showInfoLogs("product currencyCode ::${products[i].currencyCode}");
     AppLogs.showInfoLogs("product currencySymbol ::${products[i].currencySymbol}");
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

     Map<String, dynamic>? checkSubscriptionData ;
    if(checkSubscriptionApi.isNotEmpty) {
      checkSubscriptionData = await service
          .checkSubscription(
          apiType: checkSubscriptonApiRequestType,
          apiUrl: checkSubscriptionApi
      );
    }

    // Group by productId
    final Map<String, List<ProductDetails>> grouped = {};
    for (var product in subscriptionProducts) {
      grouped.putIfAbsent(product.id, () => []).add(product);
    }

// Pick preferred version (free trial if first time, paid if not)
   List<ProductDetails> filteredProducts = [];
   for (var entry in grouped.entries) {
     bool hasPurchasedBefore = state.purchases.any((p) => p.productID == entry.key);

     if (!hasPurchasedBefore) {
       // First time: pick free trial if available
       filteredProducts.add(
           entry.value.firstWhere(
                   (p) => p.price == "Free" && p.rawPrice == 0.0,
               orElse: () => entry.value.first
           )
       );
     } else {
       // Returning: pick paid version
       filteredProducts.add(
           entry.value.firstWhere(
                   (p) => p.price != "Free" && p.rawPrice > 0.0,
               orElse: () => entry.value.first
           )
       );
       emit(state.copyWith( isSubscribed: true,
         subscriptionType: checkSubscriptionData?["data"]["subscriptionType"]?? 1,
         subsExpiryDate: checkSubscriptionData?["data"]["expiryDate"]?? "",));
     }
   }

   bool isActive = false;

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
    if (Platform.isAndroid) {
      add(GetOldPurchaseEvent());
    }

  }

 Future<void> getOldPurchaseEvent(GetOldPurchaseEvent event,Emitter<SubscriptionState> emit) async {
    final InAppPurchaseAndroidPlatformAddition androidAddition =
    inAppPurchase.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

    final QueryPurchaseDetailsResponse response = await androidAddition.queryPastPurchases();

    if (response.error != null) {
      return;
    }
    if (response.pastPurchases.isNotEmpty) {

      for (var purchase in response.pastPurchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          emit(state.copyWith(purchases: response.pastPurchases,pastSubscriptionId: purchase.productID));
          break;
        }
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


      ProductDetails purchaseProduct = await service.selectedPlan(state.subsExpiryDate,
          state.products,state.selectedItem,
          subscriptionProductIds,state.purchases);

      await service.buyProduct(
          purchaseProduct
      );
    }

  }

  Future<void> downgradeOrUpgradeEvent(DowngradeOrUpgradeEvent event,Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isClicked: true,loader: true));
    final oldProductId = state.pastSubscriptionId;
    AppLogs.showInfoLogs("oldProductId: $oldProductId");
    AppLogs.showInfoLogs("state.selectedItem: ${state.selectedItem}");
    ProductDetails purchaseProduct = await service.selectedPlan(state.subsExpiryDate,state.products,state.selectedItem,
        subscriptionProductIds,state.purchases);
    AppLogs.showInfoLogs("purchaseProduct: ${purchaseProduct.price}");

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
      if (purchase.status == PurchaseStatus.purchased) {
        service.inAppPurchase.completePurchase(purchase);
        if(state.isClicked == true){
          add(VerifyPurchaseEvent(purchaseDetails: purchase));


        }
      }
    }

    for (var purchase in event.purchases) {
      AppLogs.showInfoLogs("purchase.status: ${purchase.status}");
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
          if (purchase.pendingCompletePurchase) {
            await service.inAppPurchase.completePurchase(purchase);
            if (state.isClicked==true) {
              add(VerifyPurchaseEvent(purchaseDetails: purchase));
            }
          }
          break;
        case PurchaseStatus.restored:
          if (purchase.pendingCompletePurchase) {
            await service.inAppPurchase.completePurchase(purchase);
          }
          if (state.isClicked==true) {
            add(VerifyPurchaseEvent(purchaseDetails: purchase));
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
        selectedProductId: state.subscriptionProducts[event.selectedItem].id,
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