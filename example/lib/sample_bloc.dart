

import 'package:in_app_subscription_bundle/in_app_subscription_bundle.dart';
import 'package:in_app_subscription_bundle_example/sample_event.dart';
import 'package:in_app_subscription_bundle_example/sample_state.dart';


// SampleBloc implementation
class SampleBloc extends Bloc<SampleEvent, SampleState> {
  late StreamSubscription _subscriptionManagerListener;

  SampleBloc() : super(SampleState()) {
    on<LoadSubscriptionStatus>(_onLoadSubscriptionStatus);
    on<BuySubscriptionEvent>(_onBuySubscription);
    on<SaveSubscriptionDataEvent>(_onSaveSubscription);



    // on<_SubscriptionStateChanged>((event, emit) {
    //   emit(SubscriptionLoaded(event.subscriptionState));
    // });
  }

  Future<void> _onLoadSubscriptionStatus(
      LoadSubscriptionStatus event, Emitter<SampleState> emit) async {
    emit(state.copyWith(subscriptionLoading: true));
    try {
      // Wait for SubscriptionState from the listener to update UI
    } catch (e) {
      emit(state.copyWith(subscriptionLoading: false, subscriptionError:"Initialization failed: $e"));
    }
  }

  Future<void> _onBuySubscription(
      BuySubscriptionEvent event, Emitter<SampleState> emit) async {
    try {
      // Result will reflect in subscriptionStateStream
    } catch (e) {
      emit(state.copyWith(subscriptionError:"Purchase failed: $e"));
    }
  }

  Future<void> _onSaveSubscription(
      SaveSubscriptionDataEvent event, Emitter<SampleState> emit) async {
    emit(state.copyWith(subscriptionLoading: true));
    try {

    } catch (e) {
      emit(state.copyWith(subscriptionLoading: false, subscriptionError:"Save failed: $e"));
    }
  }

  @override
  Future<void> close() {
    _subscriptionManagerListener.cancel();
    return super.close();
  }
}
