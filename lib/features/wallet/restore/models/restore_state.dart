import 'package:equatable/equatable.dart';

class RestoreState extends Equatable {
  final bool isLoading;
  final String? error;
  final String? mnemonicError;

  const RestoreState({this.isLoading = false, this.error, this.mnemonicError});

  RestoreState copyWith({bool? isLoading, String? error, String? mnemonicError}) {
    return RestoreState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Intentionally nullable to clear errors
      mnemonicError: mnemonicError, // Intentionally nullable
    );
  }

  @override
  List<Object?> get props => <Object?>[isLoading, error, mnemonicError];
}
