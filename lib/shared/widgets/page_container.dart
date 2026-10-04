import 'package:flutter/material.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Padding(
            padding:
                padding ??
                EdgeInsets.fromLTRB(
                  MediaQuery.sizeOf(context).width < 400 ? 16 : 24,
                  12,
                  MediaQuery.sizeOf(context).width < 400 ? 16 : 24,
                  0,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
