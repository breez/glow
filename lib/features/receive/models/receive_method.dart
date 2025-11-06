enum ReceiveMethod {
  lightning('Lightning'),
  bitcoin('BTC Address');

  const ReceiveMethod(this.label);
  final String label;
}
