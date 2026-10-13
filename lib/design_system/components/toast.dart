import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../icons/synk_icon.dart';
import '../tokens/synk_motion.dart';
import '../tokens/synk_palette.dart';
import '../tokens/synk_radius.dart';
import '../tokens/synk_spacing.dart';
import '../tokens/synk_theme.dart';
import '../tokens/synk_typography.dart';
import 'synk_text.dart';

enum ToastVariant { defaultVariant, destructive, success }

/// One toast on screen.
@immutable
class ToastMessage {
  const ToastMessage({
    required this.id,
    required this.title,
    this.description,
    this.variant = ToastVariant.defaultVariant,
  });

  final int id;
  final String title;
  final String? description;
  final ToastVariant variant;

  @override
  String toString() => 'ToastMessage#$id($variant, $title, $description)';
}

/// Toast queue (ported from `ToastState`).
///
/// An identical title plus description that is already visible is dropped; at most
/// [maxVisible] stay on screen (the oldest is evicted); each toast dismisses itself after
/// [life]. Dispose the controller to cancel the pending timers.
class ToastController extends ChangeNotifier {
  ToastController({this.life = SynkMotion.toastLife, this.maxVisible = 3})
    : assert(maxVisible > 0, 'maxVisible must be positive');

  final Duration life;
  final int maxVisible;

  final List<ToastMessage> _visible = <ToastMessage>[];
  final Map<int, Timer> _timers = <int, Timer>{};
  int _nextId = 1;
  bool _disposed = false;

  /// Toasts on screen, oldest first.
  List<ToastMessage> get visible => List<ToastMessage>.unmodifiable(_visible);

  void show(
    String title, {
    String? description,
    ToastVariant variant = ToastVariant.defaultVariant,
  }) {
    if (_disposed) return;
    final duplicate = _visible.any(
      (m) => m.title == title && m.description == description,
    );
    if (duplicate) return;
    final message = ToastMessage(
      id: _nextId++,
      title: title,
      description: description,
      variant: variant,
    );
    _visible.add(message);
    while (_visible.length > maxVisible) {
      _remove(_visible.first.id);
    }
    _timers[message.id] = Timer(life, () => dismiss(message.id));
    notifyListeners();
  }

  void error(String title, [String? description]) =>
      show(title, description: description, variant: ToastVariant.destructive);

  void success(String title, [String? description]) =>
      show(title, description: description, variant: ToastVariant.success);

  void dismiss(int id) {
    if (_remove(id)) notifyListeners();
  }

  bool _remove(int id) {
    _timers.remove(id)?.cancel();
    final before = _visible.length;
    _visible.removeWhere((m) => m.id == id);
    return _visible.length != before;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}

/// Exposes the [ToastController] below a [ToastHost].
class ToastScope extends InheritedNotifier<ToastController> {
  const ToastScope({
    required ToastController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The nearest controller. Looks it up without subscribing, so callers do not rebuild on
  /// every toast.
  static ToastController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(() {
      if (controller == null) {
        throw FlutterError(
          'ToastScope.of() was called with a context that does not contain a ToastHost.\n'
          'Wrap the app (for example in MaterialApp.builder) in a ToastHost.',
        );
      }
      return true;
    }());
    return controller!;
  }

  static ToastController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ToastScope>()?.notifier;
}

extension ToastBuildContext on BuildContext {
  /// The app's toast queue: `context.toast.error('Could not save')`.
  ToastController get toast => ToastScope.of(this);
}

/// Places the toasts above [child] at the app root and provides a [ToastScope].
///
/// Put it above the navigator (for example in `MaterialApp.builder`) so toasts sit above
/// sheets and dialogs. Toasts are centred at the top: top padding max(12, status bar + 8),
/// side 16, gap 8, each at most 400 wide. The host does not own [controller].
class ToastHost extends StatefulWidget {
  const ToastHost({required this.controller, required this.child, super.key});

  final ToastController controller;
  final Widget child;

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastEntry {
  _ToastEntry(this.message);

  final ToastMessage message;
  bool exiting = false;
}

class _ToastHostState extends State<ToastHost> {
  /// Visible toasts plus the ones still animating out.
  final List<_ToastEntry> _entries = <_ToastEntry>[];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    _reconcile();
  }

  @override
  void didUpdateWidget(ToastHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _reconcile();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    setState(_reconcile);
  }

  void _reconcile() {
    final visible = widget.controller.visible;
    final ids = <int>{for (final m in visible) m.id};
    for (final entry in _entries) {
      if (!ids.contains(entry.message.id)) entry.exiting = true;
    }
    final known = <int>{for (final e in _entries) e.message.id};
    for (final message in visible) {
      if (!known.contains(message.id)) _entries.add(_ToastEntry(message));
    }
  }

  void _exited(int id) {
    if (!mounted) return;
    setState(() => _entries.removeWhere((e) => e.message.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final statusBar = MediaQuery.maybePaddingOf(context)?.top ?? 0;
    final top = math.max(12.0, statusBar + 8);
    return ToastScope(
      controller: widget.controller,
      child: Directionality(
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_entries.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, top, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in _entries)
                        _ToastTile(
                          key: ValueKey<int>(entry.message.id),
                          message: entry.message,
                          exiting: entry.exiting,
                          onClose: () =>
                              widget.controller.dismiss(entry.message.id),
                          onExited: () => _exited(entry.message.id),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Tile: enter / exit / swipe
// ---------------------------------------------------------------------------------------

class _ToastTile extends StatefulWidget {
  const _ToastTile({
    required this.message,
    required this.exiting,
    required this.onClose,
    required this.onExited,
    super.key,
  });

  final ToastMessage message;
  final bool exiting;
  final VoidCallback onClose;
  final VoidCallback onExited;

  @override
  State<_ToastTile> createState() => _ToastTileState();
}

class _ToastTileState extends State<_ToastTile> with TickerProviderStateMixin {
  static const double _enterOffset = 160;
  static const double _swipeDistance = 40;
  static const double _swipeVelocity = 600;
  static const double _downDamping = 0.2;
  static const double _fadeDistance = 120;

  /// 0 to 1 over 220 ms: slides in from above.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: SynkMotion.toastIn,
  );

  /// 0 to 1 over 180 ms: fades out.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: SynkMotion.toastOut,
  );

  /// Vertical drag offset in dp (negative is up).
  late final AnimationController _drag = AnimationController.unbounded(
    vsync: this,
  );

  bool _swiped = false;

  @override
  void initState() {
    super.initState();
    unawaited(_enter.forward());
    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onExited();
    });
    if (widget.exiting) _beginExit();
  }

  @override
  void didUpdateWidget(_ToastTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exiting && !oldWidget.exiting) _beginExit();
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _beginExit() {
    unawaited(_exit.forward());
    if (_swiped) {
      unawaited(
        _drag.animateTo(
          -_enterOffset,
          duration: SynkMotion.toastOut,
          curve: SynkMotion.fastOutSlowIn,
        ),
      );
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (widget.exiting) return;
    _drag.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.exiting) return;
    final dy = details.delta.dy;
    _drag.value += dy > 0 ? dy * _downDamping : dy;
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.exiting) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_drag.value < -_swipeDistance || velocity < -_swipeVelocity) {
      _swiped = true;
      widget.onClose();
    } else {
      unawaited(
        _drag.animateWith(
          SpringSimulation(
            SpringDescription.withDampingRatio(
              mass: 1,
              stiffness: 1500,
              ratio: 1,
            ),
            _drag.value,
            0,
            velocity,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: ToastCard(message: widget.message, onClose: widget.onClose),
    );
    return IgnorePointer(
      ignoring: widget.exiting,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _exit, _drag]),
        child: card,
        builder: (context, child) {
          final enter = SynkMotion.popover.transform(_enter.value);
          final exit = SynkMotion.fastOutSlowIn.transform(_exit.value);
          final drag = _drag.value;
          final alpha =
              enter * (1 + drag / _fadeDistance).clamp(0.0, 1.0) * (1 - exit);
          // The space the toast takes collapses during the last part of the fade so the
          // toasts below glide up instead of jumping.
          final collapse = SynkMotion.fastOutSlowIn.transform(
            ((_exit.value - 0.6) / 0.4).clamp(0.0, 1.0),
          );
          return Align(
            alignment: Alignment.topCenter,
            heightFactor: 1 - collapse,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: alpha.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - enter) * -_enterOffset + drag),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------------------

/// The toast surface: radius 14, card colour, 1dp border, soft shadow, an icon tile, the
/// title with an optional description and a close button.
///
/// [ToastHost] renders it; golden tests pump it directly. Set [animateIcon] to `false` to skip
/// the success icon's pop.
class ToastCard extends StatelessWidget {
  const ToastCard({
    required this.message,
    this.onClose,
    this.animateIcon = true,
    super.key,
  });

  final ToastMessage message;
  final VoidCallback? onClose;
  final bool animateIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, tint, spoken) = switch (message.variant) {
      ToastVariant.destructive => (
        SynkIcons.alert,
        colors.destructive,
        'Error',
      ),
      ToastVariant.success => (SynkIcons.check, SynkPalette.success, 'Success'),
      ToastVariant.defaultVariant => (
        SynkIcons.info,
        // The dark theme's primary is too dim for an icon on the dark card.
        colors.primaryText,
        null,
      ),
    };
    final description = message.description;
    final announcement = [?spoken, message.title, ?description].join('. ');

    Widget iconWidget = SynkIcon(icon, size: SynkIconSize.base, color: tint);
    if (message.variant == ToastVariant.success && animateIcon) {
      iconWidget = _PopIn(child: iconWidget);
    }

    final content = Semantics(
      container: true,
      liveRegion: true,
      label: announcement,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0x15 / 255),
              ),
              child: SizedBox.square(
                dimension: 32,
                child: Center(child: iconWidget),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SynkText(
                    message.title,
                    variant: SynkTextVariant.toastTitle,
                    maxLines: 3,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    SynkText(
                      description,
                      variant: SynkTextVariant.toastDescription,
                      maxLines: 5,
                    ),
                  ],
                ],
              ),
            ),
            // Room for the close button, which is laid over it with a larger hit area.
            const SizedBox(width: 12 + 24),
          ],
        ),
      ),
    );

    final closeButton = Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: 48,
      child: Semantics(
        button: true,
        label: 'Dismiss notification',
        excludeSemantics: true,
        onTap: onClose,
        child: InkResponse(
          onTap: onClose,
          radius: 18,
          highlightShape: BoxShape.circle,
          containedInkWell: false,
          highlightColor: colors.foreground.withValues(alpha: 0.08),
          splashColor: colors.foreground.withValues(alpha: 0.08),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SynkIcon(
                  SynkIcons.close,
                  size: SynkIconSize.md,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: SynkSpace.toastMax),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: SynkRadius.mdAll,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000)
                    .withValues(alpha: colors.isDark ? 0.45 : 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(children: [content, closeButton]),
          ),
        ),
      ),
    );
  }
}

/// Success-icon pop: scale 1 to 1.18 over 110 ms, then a spring back to 1.
class _PopIn extends StatefulWidget {
  const _PopIn({required this.child});

  final Widget child;

  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    unawaited(
      _scale
          .animateTo(
            1.18,
            duration: const Duration(milliseconds: 110),
            curve: SynkMotion.fastOutSlowIn,
          )
          .then<void>((_) {
            if (!mounted) return;
            unawaited(
              _scale.animateWith(
                SpringSimulation(SynkMotion.iconPop, 1.18, 1, 0),
              ),
            );
          }),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      child: widget.child,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
    );
  }
}
