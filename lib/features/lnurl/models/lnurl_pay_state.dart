import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:equatable/equatable.dart';

/// State for LNURL-Pay and Lightning Address flows
sealed class LnurlPayState extends Equatable {
  const LnurlPayState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state - showing amount input form
class LnurlPayInitial extends LnurlPayState {
  final LnurlPayRequestDetails payRequest;
  final BigInt minSendable;
  final BigInt maxSendable;
  final int commentAllowed;

  const LnurlPayInitial({
    required this.payRequest,
    required this.minSendable,
    required this.maxSendable,
    required this.commentAllowed,
  });

  @override
  List<Object?> get props => <Object?>[payRequest, minSendable, maxSendable, commentAllowed];
}

/// Preparing the payment (calling prepareLnurlPay)
class LnurlPayPreparing extends LnurlPayState {
  const LnurlPayPreparing();
}

/// Payment is prepared and ready to send
class LnurlPayReady extends LnurlPayState {
  final PrepareLnurlPayResponse prepareResponse;
  final BigInt amountSats;
  final BigInt feeSats;
  final String? comment;

  const LnurlPayReady({
    required this.prepareResponse,
    required this.amountSats,
    required this.feeSats,
    this.comment,
  });

  @override
  List<Object?> get props => <Object?>[prepareResponse, amountSats, feeSats, comment];
}

/// Sending the payment
class LnurlPaySending extends LnurlPayState {
  final PrepareLnurlPayResponse prepareResponse;

  const LnurlPaySending({required this.prepareResponse});

  @override
  List<Object?> get props => <Object?>[prepareResponse];
}

/// Payment sent successfully
class LnurlPaySuccess extends LnurlPayState {
  final Payment payment;
  final SuccessAction? successAction;

  const LnurlPaySuccess({required this.payment, this.successAction});

  @override
  List<Object?> get props => <Object?>[payment, successAction];
}

/// Payment failed
class LnurlPayError extends LnurlPayState {
  final String message;
  final String? technicalDetails;

  const LnurlPayError({required this.message, this.technicalDetails});

  @override
  List<Object?> get props => <Object?>[message, technicalDetails];
}
