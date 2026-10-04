import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveSheet extends StatelessWidget {
  const ResponsiveSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Bound the scroll area above the keyboard, including in landscape.
    final availableHeight = math.max(
      0.0,
      media.size.height - media.viewInsets.bottom - media.padding.top - 56,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}
