class OnboardingState {
  bool isLoading;

  OnboardingState({this.isLoading = false});

  OnboardingState copyWith({bool? isLoading}) {
    return OnboardingState(isLoading: isLoading ?? this.isLoading);
  }
}
