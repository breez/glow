import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiveFormControllers {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController amount = TextEditingController();
  final TextEditingController description = TextEditingController();

  void dispose() {
    amount.dispose();
    description.dispose();
  }
}

final Provider<ReceiveFormControllers> receiveFormControllersProvider =
    Provider.autoDispose<ReceiveFormControllers>((Ref ref) {
      final ReceiveFormControllers controllers = ReceiveFormControllers();
      ref.onDispose(controllers.dispose);
      return controllers;
    });
