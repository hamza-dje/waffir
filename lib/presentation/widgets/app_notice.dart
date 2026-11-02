import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design/design.dart';
import '../design/motion.dart';

/// One non-modal message above the Navigator, including sheets and dialogs.
class AppNoticeHost extends StatefulWidget {
  const AppNoticeHost({super.key, required this.child});
  final Widget child;

  static void show(BuildContext context, String message, {bool error = false}) {
    context
        .findAncestorStateOfType<_AppNoticeHostState>()
        ?.show(message, error);
  }

  @override
  State<AppNoticeHost> createState() => _AppNoticeHostState();
}

class _AppNoticeHostState extends State<AppNoticeHost>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
      reverseDuration: AppMotion.exit,
      animationBehavior: AnimationBehavior.preserve);
  late final progress = CurvedAnimation(
      parent: controller,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut);
  Timer? timer;
  String? message;
  bool error = false;

  void show(String text, bool isError) {
    timer?.cancel();
    setState(() {
      message = text;
      error = isError;
    });
    controller.forward();
    // Keep the message available until dismissed for assistive navigation.
    if (!MediaQuery.accessibleNavigationOf(context)) {
      timer = Timer(Duration(seconds: isError ? 6 : 4), dismiss);
    }
  }

  Future<void> dismiss() async {
    timer?.cancel();
    try {
      await controller.reverse().orCancel;
      if (mounted) setState(() => message = null);
    } on TickerCanceled {
      // A new message or disposal interrupted the exit.
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    progress.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    controller.duration = reduce ? AppMotion.reduced : AppMotion.standard;
    controller.reverseDuration = reduce ? AppMotion.reduced : AppMotion.exit;
    return Stack(fit: StackFit.expand, children: [
      widget.child,
      if (message != null)
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
                bottom: false,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        pageInset, spaceTight, pageInset, 0),
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: AnimatedBuilder(
                                animation: progress,
                                builder: (context, child) =>
                                    Transform.translate(
                                        key: const ValueKey('notice-motion'),
                                        offset: Offset(
                                            0,
                                            reduce
                                                ? 0
                                                : -spaceRelated *
                                                    (1 - progress.value)),
                                        child: Opacity(
                                            opacity: progress.value,
                                            child: child)),
                                child: Semantics(
                                    liveRegion: true,
                                    container: true,
                                    child: Stack(children: [
                                      // A message never blocks the controls
                                      // underneath it. Only Close takes taps.
                                      IgnorePointer(
                                          child: Material(
                                              color: surfaceHigh,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      sectionRadius),
                                              child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      spaceRelated),
                                                  child: Row(children: [
                                                    SourceIcon(
                                                        error
                                                            ? 'alert-circle'
                                                            : 'check',
                                                        color: error
                                                            ? danger
                                                            : mint,
                                                        size: 20),
                                                    const SizedBox(
                                                        width: listItemGap),
                                                    Expanded(
                                                        child: Text(message!,
                                                            style: type(14,
                                                                weight:
                                                                    FontWeight
                                                                        .w500,
                                                                height: 1.4))),
                                                    const SizedBox(
                                                        width:
                                                            compactActionHeight),
                                                  ])))),
                                      Positioned(
                                          top: 0,
                                          bottom: 0,
                                          right: spaceTight,
                                          child: Center(
                                              child: Semantics(
                                                  container: true,
                                                  label: 'Dismiss message',
                                                  button: true,
                                                  child: IconButton(
                                                      onPressed: dismiss,
                                                      constraints: const BoxConstraints
                                                          .tightFor(
                                                          width:
                                                              compactActionHeight,
                                                          height:
                                                              compactActionHeight),
                                                      icon: Transform.rotate(
                                                          angle: math.pi / 4,
                                                          child: const SourceIcon(
                                                              'plus',
                                                              size: 20,
                                                              color:
                                                                  secondaryText))))))
                                    ])))))))),
    ]);
  }
}
