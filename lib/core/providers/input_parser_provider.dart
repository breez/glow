import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/core/providers/sdk_provider.dart';

/// Provider for parsing input strings using the SDK
final inputParserProvider = Provider<InputParser>((ref) {
  return InputParser(ref);
});

class InputParser {
  final Ref _ref;

  InputParser(this._ref);

  /// Parse input string using SDK's parse API
  Future<ParseResult> parse(String input) async {
    try {
      final sdk = await _ref.watch(sdkProvider.future);

      log.i('Parsing input: ${input.substring(0, input.length > 50 ? 50 : input.length)}...');

      // Call SDK parse method
      final inputType = await sdk.parse(input: input);

      log.i('Successfully parsed input type: ${inputType.runtimeType}');
      return ParseResult.success(inputType);
    } catch (e, stackTrace) {
      log.e('Error parsing input', error: e, stackTrace: stackTrace);
      return ParseResult.error('Failed to parse: ${e.toString()}');
    }
  }
}

/// Result wrapper for parse operations
sealed class ParseResult {
  const ParseResult();

  factory ParseResult.success(InputType inputType) = ParseSuccess;
  factory ParseResult.error(String message) = ParseError;

  T when<T>({required T Function(InputType inputType) success, required T Function(String message) error}) {
    return switch (this) {
      ParseSuccess(:final inputType) => success(inputType),
      ParseError(:final message) => error(message),
    };
  }
}

class ParseSuccess extends ParseResult {
  final InputType inputType;
  const ParseSuccess(this.inputType);
}

class ParseError extends ParseResult {
  final String message;
  const ParseError(this.message);
}
