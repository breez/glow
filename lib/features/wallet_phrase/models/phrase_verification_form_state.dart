import 'package:equatable/equatable.dart';

/// State for phrase verification
class PhraseVerificationFormState extends Equatable {
  final List<int> wordIndices;
  final bool isVerifying;
  final String? errorMessage;

  const PhraseVerificationFormState({
    required this.wordIndices,
    this.isVerifying = false,
    this.errorMessage,
  });

  PhraseVerificationFormState copyWith({
    List<int>? wordIndices,
    bool? isVerifying,
    String? errorMessage,
  }) {
    return PhraseVerificationFormState(
      wordIndices: wordIndices ?? this.wordIndices,
      isVerifying: isVerifying ?? this.isVerifying,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[wordIndices, isVerifying, errorMessage];
}
