import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Creates an [PageController] automatically disposed.
///
///
/// [initialValue], [lowerBound], [upperBound] and [debugLabel]
/// are ignored after the first call.
///
/// See also:
///   * [AnimationController], the created object.
///   * [useAnimation], to listen to the created [AnimationController].
///
PageController usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
  List<Object> keys,
}) =>
    use(
      _PageControllerHook(
        initialPage: initialPage,
        keepPage: keepPage,
        viewportFraction: viewportFraction,
        keys: keys,
      ),
    );

class _PageControllerHook extends Hook<PageController> {
  const _PageControllerHook({
    this.initialPage,
    this.keepPage,
    this.viewportFraction,
    List<Object> keys,
  }) : super(keys: keys);

  final int initialPage;
  final bool keepPage;
  final double viewportFraction;

  @override
  HookState<PageController, Hook<PageController>> createState() =>
      _PageControllerHookState();
}

class _PageControllerHookState
    extends HookState<PageController, _PageControllerHook> {
  PageController _pageController;

  @override
  void initHook() {
    super.initHook();
    _pageController = PageController(
      initialPage: hook.initialPage,
      keepPage: hook.keepPage,
      viewportFraction: hook.viewportFraction,
    );
  }

  @override
  PageController build(BuildContext context) => _pageController;

  @override
  void dispose() {
    _pageController.dispose();
  }
}
