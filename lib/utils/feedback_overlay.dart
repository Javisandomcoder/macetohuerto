import 'dart:async';
import 'package:flutter/material.dart';

class FeedbackOverlay {
  static void show(
    BuildContext context, {
    required String text,
    IconData icon = Icons.check_circle_outline,
    Color? color,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final theme = Theme.of(context);
    final bg = color ?? theme.colorScheme.primary;
    final fg = theme.colorScheme.onPrimary;

    late OverlayEntry entry;
    final animationKey = GlobalKey<_FeedbackAnimState>();

    entry = OverlayEntry(
      builder: (ctx) => _FeedbackAnim(
        key: animationKey,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: fg),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    // Auto-remove after duration
    Timer(duration, () async {
      animationKey.currentState?.dismiss(() {
        entry.remove();
      });
    });
  }

  static void showWithUndo(
    BuildContext context, {
    required String text,
    required String undoLabel,
    required VoidCallback onUndo,
    IconData icon = Icons.delete_outline,
    Color? color,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final theme = Theme.of(context);
    final bg = color ?? theme.colorScheme.errorContainer;
    final fg = theme.colorScheme.onErrorContainer;

    late OverlayEntry entry;
    final animationKey = GlobalKey<_FeedbackAnimState>();

    entry = OverlayEntry(
      builder: (ctx) => _FeedbackAnim(
        key: animationKey,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: fg),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            onUndo();
                            animationKey.currentState?.dismiss(() {
                              entry.remove();
                            });
                          },
                          style: TextButton.styleFrom(foregroundColor: fg.withValues(alpha: 0.95)),
                          child: Text(undoLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Timer(duration, () async {
      animationKey.currentState?.dismiss(() {
        entry.remove();
      });
    });
  }
}

class _FeedbackAnim extends StatefulWidget {
  final Widget child;
  const _FeedbackAnim({super.key, required this.child});

  @override
  State<_FeedbackAnim> createState() => _FeedbackAnimState();
}

class _FeedbackAnimState extends State<_FeedbackAnim>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 220),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.2),
    end: Offset.zero,
  ).animate(_fade);

  void dismiss(VoidCallback onDone) async {
    await _c.reverse();
    onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
