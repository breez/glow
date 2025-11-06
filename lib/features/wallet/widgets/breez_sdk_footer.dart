import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

const double _kBreezBottomSheetHeight = 60.0;

class BreezSdkFooter extends StatelessWidget {
  const BreezSdkFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Aligns footer with bottom actions bar
      height: _kBreezBottomSheetHeight + 8.0 + MediaQuery.of(context).viewPadding.bottom,
      child: Column(
        children: <Widget>[
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'assets/svg/drawer_footer.svg',
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcATop),
                height: 39,
                width: 183,
                fit: BoxFit.scaleDown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
