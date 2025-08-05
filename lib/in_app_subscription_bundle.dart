
import 'in_app_subscription_bundle_platform_interface.dart';


export 'package:flutter_bloc/flutter_bloc.dart';
export 'dart:convert';
export 'dart:io';
export 'package:flutter/material.dart';
export 'package:http_parser/http_parser.dart';
export 'package:flutter/gestures.dart';
export 'dart:async';
export 'package:flutter/services.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter_svg/svg.dart';

//network
export 'package:dio/dio.dart';

//storage
export 'package:get_storage/get_storage.dart';

//router
export 'package:go_router/go_router.dart';

//subscription
export 'package:in_app_purchase/in_app_purchase.dart';
export 'package:in_app_purchase_android/in_app_purchase_android.dart';
export 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
export 'package:in_app_purchase_android/billing_client_wrappers.dart';

//utils
export 'package:project_setup/project_setup.dart';

//modules
export '../features/subscripton/service/subscription_service.dart';
export '../features/subscripton/bloc/subscription_event.dart';
export '../features/subscripton/bloc/subs_bloc.dart';
export '../features/subscripton/bloc/subscription_state.dart';
export '../features/subscripton/model/subscription_products_response.dart';
export '../features/subscripton/model/subscription_request.dart';
export 'subscription_manager.dart';

class InAppSubscriptionBundle {
  Future<String?> getPlatformVersion() {
    return InAppSubscriptionBundlePlatform.instance.getPlatformVersion();
  }
}
