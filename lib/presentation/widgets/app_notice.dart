import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design/design.dart';
import '../design/motion.dart';

enum NoticeKind { success, alert, error }

/// One non-modal message above the Navigator, including sheets and dialogs.
class AppNoticeHost extends StatefulWidget {
  const AppNoticeHost({super.key, required this.child});
  final Widget child;

  static void show(BuildContext context, String message,
      {NoticeKind kind = NoticeKind.success}) {
    context.findAncestorStateOfType<_AppNoticeHostState>()?.show(message, kind);
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
  NoticeKind kind = NoticeKind.success;

  void show(String text, NoticeKind nextKind) {
    timer?.cancel();
    setState(() {
      message = text;
      kind = nextKind;
    });
    controller.forward();
    // Keep the message available until dismissed for assistive navigation.
    if (!MediaQuery.accessibleNavigationOf(context)) {
      timer = Timer(
          Duration(seconds: nextKind == NoticeKind.success ? 4 : 6), dismiss);
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
                                builder: (context, child) => Transform.translate(
                                    key: const ValueKey('notice-motion'),
                                    offset: Offset(
                                        0,
                                        reduce
                                            ? 0
                                            : -spaceRelated *
                                                (1 - progress.value)),
                                    child: Opacity(
                                        opacity: progress.value, child: child)),
                                child: AppNoticeCard(
                                    message: message!,
                                    kind: kind,
                                    onDismiss: dismiss))))))),
    ]);
  }
}

class AppNoticeCard extends StatelessWidget {
  const AppNoticeCard(
      {super.key,
      required this.message,
      required this.kind,
      required this.onDismiss});
  final String message;
  final NoticeKind kind;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      NoticeKind.success => noticeSuccessSurface,
      NoticeKind.alert => noticeAlertSurface,
      NoticeKind.error => noticeErrorSurface,
    };
    final accent = switch (kind) {
      NoticeKind.success => mint,
      NoticeKind.alert => caution,
      NoticeKind.error => danger,
    };
    return Semantics(
        liveRegion: true,
        container: true,
        child: Stack(children: [
          IgnorePointer(
              child: Material(
                  key: const ValueKey("notice-surface"),
                  color: color,
                  borderRadius: BorderRadius.circular(controlRadius),
                  child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(minHeight: actionHeight),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: spaceTight),
                          child: Row(children: [
                            SizedBox.square(
                                dimension: compactActionHeight,
                                child: Center(
                                    child: SourceIcon(
                                        kind == NoticeKind.success
                                            ? "check"
                                            : "alert-circle",
                                        key: const ValueKey(
                                            "notice-status-icon"),
                                        color: accent,
                                        size: 20))),
                            const SizedBox(width: spaceTight),
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: spaceRelated),
                                    child: Text(message,
                                        style: type(14,
                                            weight: FontWeight.w500,
                                            height: 1.4)))),
                            const SizedBox(width: spaceTight),
                            const SizedBox(width: compactActionHeight),
                          ]))))),
          Positioned(
              top: 0,
              bottom: 0,
              right: spaceTight,
              child: Center(
                  child: Semantics(
                      container: true,
                      label: "Dismiss message",
                      button: true,
                      child: IconButton(
                          onPressed: onDismiss,
                          style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.all(spaceRelated),
                              fixedSize: const Size(
                                  compactActionHeight, compactActionHeight)),
                          icon: Transform.rotate(
                              angle: math.pi / 4,
                              child: const SourceIcon("plus",
                                  key: ValueKey("notice-dismiss-icon"),
                                  size: 20,
                                  color: secondaryText))))))
        ]));
  }
}
