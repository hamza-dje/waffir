import 'package:flutter/material.dart';
import '../design/motion.dart';

/// Fades a changed view without retaining an outgoing form or altering layout.
/// Ordinary rebuilds, including typing and saving data, do not restart motion.
class ContentTransition extends StatefulWidget {
  const ContentTransition({
    super.key,
    required this.change,
    required this.child,
    this.duration = AppMotion.standard,
    this.animateOnMount = false,
    this.fromOpacity = 0,
  });
  final Object? change;
  final Widget child;
  final Duration duration;
  final bool animateOnMount;
  final double fromOpacity;

  @override
  State<ContentTransition> createState() => _ContentTransitionState();
}

class _ContentTransitionState extends State<ContentTransition>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(vsync: this, value: 1);
  bool reduce = false;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduce = MediaQuery.disableAnimationsOf(context);
    if (!initialized) {
      initialized = true;
      if (widget.animateOnMount) fade();
    } else if (reduce && controller.isAnimating) {
      controller.value = 1;
    }
  }

  void fade() {
    // Rapid navigation continues from the current opacity, without flashing
    // back to the beginning or keeping old controls in the widget tree.
    if (!controller.isAnimating) {
      controller.value = reduce ? .97 : widget.fromOpacity;
    }
    controller.animateTo(1,
        duration: reduce ? AppMotion.reduced : widget.duration,
        curve: AppMotion.easeOut);
  }

  @override
  void didUpdateWidget(ContentTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.change != oldWidget.change) fade();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: controller, alwaysIncludeSemantics: true, child: widget.child);
}
