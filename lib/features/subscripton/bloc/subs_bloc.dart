
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
    required this.checkSubscriptionApi,
    required this.checkSubscriptonApiRequestType,
    required this.saveSubscriptionApiUrl,
    required this.subscriptionProductIds
  }) : super(SubscriptionState()) {
    on<SubscriptionInitEvent>(initEvent);
    on<VerifyPurchaseEvent>(verifyPurchaseEvent);
    on<BuyProductEvent>(buyProductEvent);
    on<PurchaseUpdateEvent>(_onPurchaseUpdate);
    on<GetOldPurchaseEvent>(getOldPurchaseEvent);
    on<DowngradeOrUpgradeEvent>(downgradeOrUpgradeEvent);
    on<SaveSubscriptionEvent>(saveSubscriptionEvent);

  }

 Future<void> initEvent(SubscriptionInitEvent event, Emitter<SubscriptionState> emit) async {


    //check subscription
    final Map<String, dynamic>? checkSubscriptionData = await service.checkSubscription(
      apiType: checkSubscriptonApiRequestType,
      apiUrl: checkSubscriptionApi
    );

    //check products availability
    final isAvailable = await service.init(subscriptionProductIds);
    if (!isAvailable) {
      AppLogs.showErrorLogs('In-App Purchases is not available on this platform.');
      return;
    }

    //load and sort products
    final subscriptionProducts = await service.loadProducts();
    service.listenToPurchaseUpdates((purchases) {
      add(PurchaseUpdateEvent(purchases));
    });
    List<ProductDetails>? products = subscriptionProducts;
    if(Platform.isIOS){products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));}

    if(checkSubscriptionData?["data"]["isSubscribed"]==true){
      for (int i = 0; i < products.length; i++)
        for (int j = 0; j < subscriptionProductIds.length; j++) {
        if (products[i].id == subscriptionProductIds[j] && products[i].price != "Free" && products[i].rawPrice != 0.0) {
          emit(state.copyWith(selectedItem: i));
          break;
        }
      }
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
            subscriptionType: state.isSubscribed == true ? state.subscriptionType : 1,
            isSubscribed: checkSubscriptionData == null ? false : checkSubscriptionData["data"]["isSubscribed"]);
      }).toList();
      SubscriptionProductsResponse productsResponse = SubscriptionProductsResponse(
        products: subscriptionItems,
      );
      emit(state.copyWith(
        products: products,
        subscriptionProducts: productsResponse.products,
        selectedProductId: productsResponse.products?[state.selectedItem].id,
      ));
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
      print('Android: Error fetching past purchases: ${response.error}');
      return;
    }
    if (response.pastPurchases.isNotEmpty) {

      for (var purchase in response.pastPurchases) {
        print("past purchase product id: ${purchase.productID}");
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
        ProductDetails purchaseProduct = await service.selectedPlan(state.subsExpiryDate,state.products,state.selectedItem);
        print("purchaseProduct: ${purchaseProduct.price}");
        await service.inAppPurchase.restorePurchases();
      }else{
        CommonUtilMethods.showSnackBar(
            context: context,
            message: "You are already subscribed."
        );
      }
    }else{
      ProductDetails purchaseProduct = await service.selectedPlan(state.subsExpiryDate,state.products,state.selectedItem);
      print("purchaseProduct: ${purchaseProduct.price}");

      await service.buyProduct(
          purchaseProduct
      );
    }

  }

  Future<void> downgradeOrUpgradeEvent(DowngradeOrUpgradeEvent event,Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(isClicked: true,loader: true));
    final oldProductId = state.pastSubscriptionId;
    print("oldProductId: $oldProductId");
    print("state.selectedItem: ${state.selectedItem}");
    ProductDetails purchaseProduct = await service.selectedPlan(state.subsExpiryDate,state.products,state.selectedItem);
    print("purchaseProduct: ${purchaseProduct.price}");

    if(state.selectedProductId==oldProductId){
      CommonUtilMethods.showSnackBar(
          context: event.context,
          message: "You are already subscribed to this plan."
      );

      emit(state.copyWith(loader: false));
      return;
    }

    await service.downgradeOrUpgrade(
      context: event.context,
      newProduct: purchaseProduct,
      currentPurchases: state.purchases,
      oldProductId: oldProductId,
    );

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
          emit(state.copyWith(loader: false, isClicked: false));
          break;
        case PurchaseStatus.canceled:
          if (Platform.isIOS) {
            await service.inAppPurchase.completePurchase(purchase);
          }
          emit(state.copyWith(loader: false, isClicked: false));
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
      print(
          "purchase receipt::::::::${Platform.isAndroid ? event.purchaseDetails.verificationData.serverVerificationData : event.purchaseDetails.verificationData.localVerificationData}");
      if (event.purchaseDetails.status == PurchaseStatus.purchased || event.purchaseDetails.status == PurchaseStatus.restored) {
        SubscriptionRequest subsRequest = SubscriptionRequest(
          productId: event.purchaseDetails.productID,
          purchaseReceipt: Platform.isAndroid
              ? event.purchaseDetails.verificationData.serverVerificationData
              : event.purchaseDetails.verificationData.localVerificationData,
          secretKey: Platform.isIOS ? event.secretKey : "",
          deviceType: Platform.isAndroid ? 1 : 2,
          subscriptionType: state.subscriptionType,
          transactionId: event.purchaseDetails.purchaseID ?? "",);


        add(SaveSubscriptionEvent(saveSubscriptionApiUrl:saveSubscriptionApiUrl,subsRequest: subsRequest ));
      }

    } catch (e, s) {
      print("purchase error::::::::$e stack trace::::$s");
    }
  }

  Future<void> saveSubscriptionEvent(SaveSubscriptionEvent event, Emitter<SubscriptionState> emit,) async {

    try {
      ApiResponse response = await ApiRepository.apiCall(
          event.saveSubscriptionApiUrl??"",
          RequestType.post,
          data: event.subsRequest
      );
      event.completer?.complete(response.data);
    } catch (e) {
      event.completer?.complete({"status": false, "message": e.toString()});
      // await NativeLogger.logTo("Subscription not purchased : ${e.toString()}");
    }

  }



  void changeSelectedItem(int i) {
    emit(state.copyWith(
        selectedItem: i,
        selectedProductId: state.subscriptionProducts[i].id,
        currentSubscriptionId: state.subscriptionProducts[i].id
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

}