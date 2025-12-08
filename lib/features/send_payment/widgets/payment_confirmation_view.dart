import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:glow/utils/formatters.dart';
import 'package:glow/widgets/card_wrapper.dart';

/// Widget that displays payment confirmation with prominent total and breakdown
class PaymentConfirmationView extends StatelessWidget {
  final String? recipientLabel;
  final String? recipientSubtitle;
  final BigInt amountSats;
  final BigInt feeSats;
  final String? description;
  final bool showScrollableDescription;

  const PaymentConfirmationView({
    required this.amountSats,
    required this.feeSats,
    this.recipientLabel,
    this.recipientSubtitle,
    this.description,
    this.showScrollableDescription = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BigInt totalSats = amountSats + feeSats;

    return Column(
      children: <Widget>[
        // Recipient and total header
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            children: <Widget>[
              if (recipientLabel != null && recipientLabel!.isNotEmpty) ...<Widget>[
                Text(
                  recipientLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    letterSpacing: 0.0,
                    height: 1.28,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (recipientSubtitle != null) ...<Widget>[
                Text(
                  recipientSubtitle!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                    height: 1.28,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 1.56,
                    ),
                    text: formatSats(totalSats),
                    children: const <InlineSpan>[
                      TextSpan(
                        text: ' sats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.52,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Payment breakdown card
        CardWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                <Widget>[
                    // Amount row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Amount:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            letterSpacing: 0.0,
                            height: 1.28,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.left,
                          maxLines: 1,
                        ),
                        Text(
                          '${formatSats(amountSats)} sats',
                          style: const TextStyle(fontSize: 18.0, color: Colors.white),
                        ),
                      ],
                    ),

                    // Fee row
                    if (feeSats > BigInt.zero) ...<Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Fee:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              height: 1.28,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                          Text(
                            '${formatSats(feeSats)} sats',
                            style: const TextStyle(fontSize: 18.0, color: Colors.white),
                          ),
                        ],
                      ),
                    ],

                    // Description (if available)
                    if (description != null && description!.isNotEmpty) ...<Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Description:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              height: 1.28,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColorLight.withValues(alpha: .1),
                                border: Border.all(
                                  color: Theme.of(context).primaryColorLight.withValues(alpha: .7),
                                ),
                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                width: MediaQuery.of(context).size.width,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: showScrollableDescription ? 120 : double.infinity,
                                    minWidth: double.infinity,
                                  ),
                                  child: showScrollableDescription
                                      ? Scrollbar(
                                          radius: const Radius.circular(16.0),
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            child: AutoSizeText(
                                              description!,
                                              style: const TextStyle(
                                                fontSize: 14.0,
                                                letterSpacing: 0.0,
                                                height: 1.156,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      : AutoSizeText(
                                          description!,
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                            height: 1.156,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ].expand((Widget widget) sync* {
                    yield widget;
                    yield const Divider(
                      height: 32.0,
                      color: Color.fromRGBO(40, 59, 74, 0.5),
                      indent: 0.0,
                      endIndent: 0.0,
                    );
                  }).toList()
                  ..removeLast(),
          ),
        ),
      ],
    );
  }
}
