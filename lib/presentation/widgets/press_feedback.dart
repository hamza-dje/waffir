import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../design/motion.dart';

/// Visual feedback only. The child keeps its gestures, focus and semantics.
/// The hit area and layout stay unchanged; scrolling cancels the press.
class PressFeedback extends StatefulWidget {
  const PressFeedback({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  int? pointer;
  Offset? origin;
  bool pressed = false;

  void release() {
    pointer = null;
    origin = null;
    if (pressed) setState(() => pressed = false);
  }

  @override
  void didUpdateWidget(PressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      pointer = null;
      origin = null;
      pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Listener(
        onPointerDown: !widget.enabled
            ? null
            : (event) {
                if (pointer != null) return;
                pointer = event.pointer;
                origin = event.position;
                setState(() => pressed = true);
              },
        onPointerMove: (event) {
          if (event.pointer == pointer &&
              origin != null &&
              (event.position - origin!).distance > kTouchSlop) {
            release();
          }
        },
        onPointerUp: (event) {
          if (event.pointer == pointer) release();
        },
        onPointerCancel: (event) {
          if (event.pointer == pointer) release();
        },
        child: AnimatedScale(
            scale: pressed && !reduce ? .96 : 1,
            duration:
                reduce || !widget.enabled ? Duration.zero : AppMotion.press,
            curve: AppMotion.easeOut,
            child: AnimatedOpacity(
                opacity: pressed && reduce ? .85 : 1,
                duration: AppMotion.reduced,
                curve: AppMotion.easeOut,
                child: widget.child)));
  }
}
