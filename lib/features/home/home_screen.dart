import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow/features/home/home_layout.dart';
import 'package:glow/core/providers/sdk_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData themeData = Theme.of(context);
    ref.watch(sdkEventListenerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeData.appBarTheme.systemOverlayStyle!.copyWith(
        systemNavigationBarColor: themeData.bottomAppBarTheme.color,
      ),
      child: const HomeLayout(),
    );
  }
}
