import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TransactionListShimmer extends StatelessWidget {
  const TransactionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: themeData.colorScheme.onSecondary,
      highlightColor: themeData.colorScheme.surface.withValues(alpha: .5),

      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (BuildContext context, int index) => const _TransactionItemShimmer(),
      ),
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
                  child: const Text(
                    '',
                    style: TextStyle(
                      fontSize: 12.25,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                      letterSpacing: 0.25,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Transform.translate(
                  offset: const Offset(-8, 0),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          height: 1.16,
                          letterSpacing: 0.39,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: const SizedBox(
                  height: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.28,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          height: 1.16,
                          letterSpacing: 0.39,
                        ),
                      ),
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
