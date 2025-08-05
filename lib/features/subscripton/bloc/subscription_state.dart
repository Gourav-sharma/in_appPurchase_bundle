
import '../../../in_app_subscription_bundle.dart';


class SubscriptionState {

  BuildContext? context;
  bool? loader = false;
  String? title = "";
  int selectedItem = 0 ;
  int? subscriptionType ;
  bool? isSubscribed = false;
  bool? purchasePending = false;
  bool? isTrial = false;
  bool? isClicked ;
  ProductDetailsResponse? productResponse ;
  String subsExpiryDate = "";
  List<ProductDetails> products = [];
  List<SubscriptionProducts> subscriptionProducts = [];
  List<PurchaseDetails> purchases = [];
  String pastSubscriptionId = "" ;
  String currentSubscriptionId = "" ;
  String? selectedProductId = "" ;

  SubscriptionState({
    this.context,
    this.loader,
    this.isSubscribed,
    this.purchasePending,
    this.isTrial,
    this.title,
    this.isClicked,
    int? selectedItem,
    this.subscriptionType,
    this.productResponse,
    String? subsExpiryDate,
    List<ProductDetails>? products,
    List<SubscriptionProducts>? subscriptionProducts,
    List<PurchaseDetails>? purchases,
    String? pastSubscriptionId,
    String? currentSubscriptionId,
    this.selectedProductId,
  }):   selectedItem = selectedItem ?? 0,
        subsExpiryDate = subsExpiryDate ?? "",
        products = products ?? [],
        subscriptionProducts = subscriptionProducts ?? [],
        purchases = purchases ?? [],
        pastSubscriptionId = pastSubscriptionId??"",
        currentSubscriptionId = currentSubscriptionId??"";

  SubscriptionState copyWith({
    BuildContext? context,
    bool? loader,
    bool? isSubscribed,
    bool? purchasePending,
    bool? isTrial,
    String? title,
    bool? isClicked,
    int? selectedItem,
    int? subscriptionType,
    ProductDetailsResponse? productResponse,
    String? subsExpiryDate,
    List<ProductDetails>? products,
    List<SubscriptionProducts>? subscriptionProducts,
    List<PurchaseDetails>? purchases,
    String? pastSubscriptionId,
    String? currentSubscriptionId,
    String? selectedProductId,
  }) {
    return SubscriptionState(
      context: context ?? this.context,
      loader: loader ?? this.loader,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      purchasePending: purchasePending ?? this.purchasePending,
      isTrial: isTrial ?? this.isTrial,
      title: title ?? this.title,
      isClicked: isClicked ?? this.isClicked,
      selectedItem: selectedItem ?? this.selectedItem,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      productResponse: productResponse ?? this.productResponse,
      subsExpiryDate: subsExpiryDate ?? this.subsExpiryDate,
      products: products ?? this.products,
      subscriptionProducts: subscriptionProducts ?? this.subscriptionProducts,
      purchases: purchases ?? this.purchases,
      pastSubscriptionId: pastSubscriptionId ?? this.pastSubscriptionId,
      currentSubscriptionId: currentSubscriptionId ?? this.currentSubscriptionId,
      selectedProductId: selectedProductId ?? this.selectedProductId,
    );
  }
}
