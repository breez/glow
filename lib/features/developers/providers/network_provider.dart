import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/logging/app_logger.dart';
import 'package:logger/logger.dart';

final Logger log = AppLogger.getLogger('NetworkProvider');

/// Network selection state
class NetworkNotifier extends Notifier<Network> {
  @override
  Network build() {
    log.d('NetworkNotifier initialized with mainnet');
    return Network.mainnet;
  }

  void setNetwork(Network network) {
    log.d('Changing network to $network from $state');
    state = network;
    log.d('Network state updated to $state');
  }
}

final NotifierProvider<NetworkNotifier, Network> networkProvider =
    NotifierProvider<NetworkNotifier, Network>(NetworkNotifier.new);
