
class SampleState {
  final bool? subscriptionLoading;
  final String? subscriptionError;

  SampleState({
    this.subscriptionLoading,
    this.subscriptionError
  });

  SampleState copyWith({
    bool? subscriptionLoading,
    String? subscriptionError
    }
      ) => SampleState(
      subscriptionLoading: subscriptionLoading ?? this.subscriptionLoading,
      subscriptionError: subscriptionError ?? this.subscriptionError
  );
}