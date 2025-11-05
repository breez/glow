import 'package:flutter/material.dart';
import 'package:glow/features/home/widgets/transactions/theme/transaction_list_text_styles.dart';
import 'package:shimmer/shimmer.dart';

class TransactionListShimmer extends StatelessWidget {
  const TransactionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: themeData.colorScheme.onSecondary,
      highlightColor: themeData.colorScheme.surface.withValues(alpha: .5),

      child: ListView.builder(itemCount: 8, itemBuilder: (context, index) => const _TransactionItemShimmer()),
    );
  }
}

class _TransactionItemShimmer extends StatelessWidget {
  const _TransactionItemShimmer();

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          color: themeData.colorScheme.surface,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Container(
                  height: 72.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .1),
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.bolt_rounded, color: Color(0xb3303234)),
                  ),
                ),
                title: Transform.translate(
                  offset: const Offset(-8, 0),
                  child: Text('', style: TransactionItemTextStyles.title, overflow: TextOverflow.ellipsis),
                ),
                subtitle: Transform.translate(
                  offset: const Offset(-8, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[Text('', style: TransactionItemTextStyles.subtitle)],
                  ),
                ),
                trailing: SizedBox(
                  height: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text('', style: TransactionItemTextStyles.amount),
                      Text('', style: TransactionItemTextStyles.fee),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
