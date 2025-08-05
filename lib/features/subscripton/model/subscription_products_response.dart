import 'dart:convert';
/// products : [{"id":"1","title":"Product 1","description":"Description of product 1","price":"19.99","rawPrice":19.99,"currencyCode":"USD","currencySymbol":"$"},{"id":"2","title":"Product 2","description":"Description of product 2","price":"29.99","rawPrice":29.99,"currencyCode":"EUR","currencySymbol":"€"},null]

SubscriptionProductsResponse subscriptionProductsResponseFromJson(String str) => SubscriptionProductsResponse.fromJson(json.decode(str));
String subscriptionProductsResponseToJson(SubscriptionProductsResponse data) => json.encode(data.toJson());
class SubscriptionProductsResponse {
  SubscriptionProductsResponse({
      List<SubscriptionProducts>? products,}){
    _products = products;
}

  SubscriptionProductsResponse.fromJson(dynamic json) {
    if (json['products'] != null) {
      _products = [];
      json['products'].forEach((v) {
        _products?.add(SubscriptionProducts.fromJson(v));
      });
    }
  }
  List<SubscriptionProducts>? _products;
SubscriptionProductsResponse copyWith({  List<SubscriptionProducts>? products,
}) => SubscriptionProductsResponse(  products: products ?? _products,
);
  List<SubscriptionProducts>? get products => _products;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_products != null) {
      map['products'] = _products?.map((v) => v.toJson()).toList();
    }
    return map;
  }

  @override
  String toString() {
    return 'SubscriptionProductsResponse{_products: $_products}';
  }
}

/// id : "1"
/// title : "Product 1"
/// description : "Description of product 1"
/// price : "19.99"
/// rawPrice : 19.99
/// currencyCode : "USD"
/// currencySymbol : "$"

SubscriptionProducts productsFromJson(String str) => SubscriptionProducts.fromJson(json.decode(str));
String productsToJson(SubscriptionProducts data) => json.encode(data.toJson());
class SubscriptionProducts {
  // Add the isSubscribed as an optional boolean field
  SubscriptionProducts({
    String? id,
    String? title,
    String? description,
    String? price,
    double? rawPrice,
    String? currencyCode,
    String? currencySymbol,
    int? selectedItem,  // Optional int field
    int? subscriptionType, // Optional int field
    bool? isSubscribed,  // Optional boolean field for subscription status
  }) {
    _id = id;
    _title = title;
    _description = description;
    _price = price;
    _rawPrice = rawPrice;
    _currencyCode = currencyCode;
    _currencySymbol = currencySymbol;
    _selectedItem = selectedItem;
    _subscriptionType = subscriptionType;
    _isSubscribed = isSubscribed ;  // Default value is false
  }

  // FromJson constructor: Include isSubscribed in the JSON mapping
  SubscriptionProducts.fromJson(dynamic json) {
    _id = json['id'];
    _title = json['title'];
    _description = json['description'];
    _price = json['price'];
    _rawPrice = json['rawPrice'];
    _currencyCode = json['currencyCode'];
    _currencySymbol = json['currencySymbol'];
    _selectedItem = json['selectedItem'];
    _subscriptionType = json['subscriptionType'];
    _isSubscribed = json['isSubscribed'] ;  // Default to false if not found in JSON
  }

  // Fields
  String? _id;
  String? _title;
  String? _description;
  String? _price;
  double? _rawPrice;
  String? _currencyCode;
  String? _currencySymbol;
  int? _selectedItem;  // Optional int field
  int? _subscriptionType;  // Optional int field
  bool? _isSubscribed;  // Added boolean field for subscription status

  // Getter methods
  String? get id => _id;
  String? get title => _title;
  String? get description => _description;
  String? get price => _price;
  double? get rawPrice => _rawPrice;
  String? get currencyCode => _currencyCode;
  String? get currencySymbol => _currencySymbol;
  int? get selectedItem => _selectedItem;
  int? get subscriptionType => _subscriptionType;
  bool? get isSubscribed => _isSubscribed;  // Getter for isSubscribed

  // CopyWith method to update the class with new values
  SubscriptionProducts copyWith({
    String? id,
    String? title,
    String? description,
    String? price,
    double? rawPrice,
    String? currencyCode,
    String? currencySymbol,
    int? selectedItem,
    int? subscriptionType,
    bool? isSubscribed,  // Added field to copyWith
  }) =>
      SubscriptionProducts(
        id: id ?? _id,
        title: title ?? _title,
        description: description ?? _description,
        price: price ?? _price,
        rawPrice: rawPrice ?? _rawPrice,
        currencyCode: currencyCode ?? _currencyCode,
        currencySymbol: currencySymbol ?? _currencySymbol,
        selectedItem: selectedItem ?? _selectedItem,
        subscriptionType: subscriptionType ?? _subscriptionType,
        isSubscribed: isSubscribed ?? _isSubscribed,  // Handle isSubscribed
      );

  // ToJson method to convert the object into JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['title'] = _title;
    map['description'] = _description;
    map['price'] = _price;
    map['rawPrice'] = _rawPrice;
    map['currencyCode'] = _currencyCode;
    map['currencySymbol'] = _currencySymbol;
    map['selectedItem'] = _selectedItem;
    map['subscriptionType'] = _subscriptionType;
    map['isSubscribed'] = _isSubscribed;  // Add isSubscribed to JSON
    return map;
  }

  @override
  String toString() {
    return 'SubscriptionProducts{_id: $_id, _title: $_title, _description: $_description, _price: $_price, _rawPrice: $_rawPrice, _currencyCode: $_currencyCode, _currencySymbol: $_currencySymbol, _selectedItem: $_selectedItem, _subscriptionType: $_subscriptionType, _isSubscribed: $_isSubscribed}';
  }
}

