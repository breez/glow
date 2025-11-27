import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card widget for displaying Lightning Address with edit and copy actions
class LightningAddressCard extends ConsumerWidget {
  static const String customizeValue = 'customize';
  final String address;
  final VoidCallback onEdit;

  const LightningAddressCard({required this.address, required this.onEdit, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData themeData = Theme.of(context);

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        // TODO(erdemyerebasmaz): Display dropdown menu in a static place that does not obstruct LN Address
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final Offset offset = details.globalPosition;

        showMenu(
          context: context,
          color: themeData.colorScheme.surfaceContainer,
          position: RelativeRect.fromRect(Rect.fromPoints(offset, offset), Offset.zero & overlay.size),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          items: const <PopupMenuItem<String>>[
            PopupMenuItem<String>(
              value: customizeValue,
              child: Row(
                children: <Widget>[Icon(Icons.edit), SizedBox(width: 8.0), Text('Customize Address')],
              ),
            ),
          ],
        ).then((String? value) {
          if (value == customizeValue) {
            onEdit();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: AutoSizeText(
              address,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                letterSpacing: 0.15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              stepGranularity: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
