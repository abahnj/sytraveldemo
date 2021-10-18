import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:hooks_riverpod/all.dart';
import 'package:sytravel/styles.dart';
import 'package:sytravel/utils.dart';

import 'leopard_page.dart';

final offsetProvider = StateProvider((ref) => 0.0);
final pageProvider = StateProvider((ref) => 0.0);

final animationNotifierProvider = ScopedProvider<AnimationNotifier>(null);
final mapAnimationNotifierProvider = ScopedProvider<AnimationNotifier>(null);

double startTop = 128.0 + 400.0 + 32 + 16 + 32 + 4;
double endTop = 128.0 + 32;
double oneThird = (startTop - endTop) / 3;

// a custom notifier class
class AnimationNotifier extends ChangeNotifier {
  final AnimationController _animationController;

  AnimationNotifier(this._animationController) {
    _animationController.addListener(_onAnimationControllerChanged);
  }

  static final provider = ChangeNotifierProvider.autoDispose
      .family<AnimationNotifier, AnimationController>(
          (_, AnimationController controller) {
    return AnimationNotifier(controller);
  });

  void forward() => _animationController.forward();
  void reverse() => _animationController.reverse();

  void _onAnimationControllerChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationControllerChanged);
    super.dispose();
  }

  double get value => _animationController.value;
}

class MainPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationController =
        useAnimationController(duration: Duration(seconds: 1));
    var _mapAnimationController =
        useAnimationController(duration: Duration(milliseconds: 1000));

    var _pageController = usePageController();

    var offset = useProvider(offsetProvider);
    var page = useProvider(pageProvider);

    double maxHeight = MediaQuery.of(context).size.height;

    useEffect(() {
      void listener() {
        offset.state = _pageController.offset;
        page.state = _pageController.page;
      }

      _pageController.addListener(listener);
      return () {
        _pageController.removeListener(listener);
      };
    }, [_pageController]);

    void _handleDragUpdate(DragUpdateDetails details) {
      _animationController.value -= details.primaryDelta / maxHeight;
    }

    void _handleDragEnd(DragEndDetails details) {
      if (_animationController.isAnimating ||
          _animationController.status == AnimationStatus.completed) return;

      final double flingVelocity =
          details.velocity.pixelsPerSecond.dy / maxHeight;
      if (flingVelocity < 0.0)
        _animationController.fling(velocity: math.max(2.0, -flingVelocity));
      else if (flingVelocity > 0.0)
        _animationController.fling(velocity: math.min(-2.0, -flingVelocity));
      else
        _animationController.fling(
            velocity: _animationController.value < 0.5 ? -2.0 : 2.0);
    }

    return Scaffold(
      body: GestureDetector(
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: ProviderScope(
          overrides: [
            animationNotifierProvider
                .overrideWithValue(AnimationNotifier(_animationController)),
            mapAnimationNotifierProvider
                .overrideWithValue(AnimationNotifier(_mapAnimationController))
          ],
          child: Stack(children: [
            MapImage(),
            SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AppBar(),
                  PageView(
                    physics: ClampingScrollPhysics(),
                    controller: _pageController,
                    children: [
                      LeopardPage(),
                      VulturePage(),
                    ],
                  ),
                  LeopardImage(),
                  VultureImage(),
                  MapButton(),
                  ShareButton(),
                  PageIndicator(),
                  ArrowIcon(),
                  TravelDetailsLabel(),
                  StartCampLabel(),
                  StartTimeLabel(),
                  BaseCampLabel(),
                  BaseTimeLabel(),
                  DistanceLabel(),
                  HorizontalTravelDots(),
                  VerticalTravelDots(),
                  VultureIconLabel(),
                  LeopardIconLabel(),
                  CurvedRoute(),
                  MapBaseCamp(),
                  MapLeopard(),
                  MapVultures(),
                  MapStartCamp()
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class MapImage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _mapAnimationProvider = useProvider(mapAnimationNotifierProvider);
    var animationValue = useListenable(_mapAnimationProvider).value;

    double scale = 1 + .3 * (1 - animationValue);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(scale, scale)
        ..rotateZ(.05 * math.pi * (1 - animationValue)),
      child: Opacity(
        opacity: animationValue,
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: Image.asset(
            'assets/map.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class VultureCircle extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    double multiplier;

    if (animationValue == 0)
      multiplier = math.max(0, 4 * page - 3);
    else
      multiplier = math.max(0, 1 - 3 * animationValue);

    double size = MediaQuery.of(context).size.width * .5 * multiplier;

    return Container(
      margin: EdgeInsets.only(bottom: 250),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lightGrey,
      ),
      width: size,
      height: size,
    );
  }
}

class MapButton extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    double opacity = math.max(0, 4 * page - 3);

    var _animationProvider = useProvider(mapAnimationNotifierProvider);

    return Positioned(
      bottom: 0,
      left: 8,
      child: Opacity(
        opacity: opacity,
        child: FlatButton(
          onPressed: () {
            _animationProvider.value == 0
                ? _animationProvider.forward()
                : _animationProvider.reverse();
          },
          child: Text('ON MAP'),
        ),
      ),
    );
  }
}

class MapHider extends HookWidget {
  final Widget child;

  const MapHider({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(mapAnimationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    return Opacity(
      opacity: math.max(0, 1 - (2 * animationValue)),
      child: child,
    );
  }
}

class TravelDetailsLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    var offset = useProvider(offsetProvider).state;

    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    return Positioned(
      top: 128 + (1 - animationValue) * (400 + 32.0 - 4),
      left: 24 + MediaQuery.of(context).size.width - offset,
      child: MapHider(
        child: Opacity(
          opacity: math.max(0, 4 * page - 3),
          child: Text(
            'Travel Details',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class StartCampLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    double opacity = math.max(0, 4 * page - 3);

    return Positioned(
      top: 128 + 400 + 32.0 + 16 + 32,
      width: (MediaQuery.of(context).size.width - 48) / 3,
      left: 24 * opacity,
      child: MapHider(
        child: Opacity(
          opacity: opacity,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Start Camp',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
            ),
          ),
        ),
      ),
    );
  }
}

class StartTimeLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    double opacity = math.max(0, 4 * page - 3);

    return Positioned(
      top: 128 + 400 + 32.0 + 16 + 32 + 40,
      width: (MediaQuery.of(context).size.width - 48) / 3,
      left: 24 * opacity,
      child: MapHider(
        child: Opacity(
          opacity: opacity,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '17:30 pm',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: lighterGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BaseCampLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    double opacity = math.max(0, 4 * page - 3);

    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    return Positioned(
      top: 128 + 32 + (1 - animationValue) * (400 + 32.0 + 16),
      width: (MediaQuery.of(context).size.width - 48) / 3,
      right: 24 * opacity,
      child: MapHider(
        child: Opacity(
          opacity: opacity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Base Camp',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
            ),
          ),
        ),
      ),
    );
  }
}

class BaseTimeLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    double opacity = math.max(0, 4 * page - 3);

    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    return Positioned(
      top: 128 + 32 + 40 + (1 - animationValue) * (400 + 32.0 + 16),
      width: (MediaQuery.of(context).size.width - 48) / 3,
      right: 24 * opacity,
      child: MapHider(
        child: Opacity(
          opacity: opacity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '19:30 pm',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: lighterGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DistanceLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    double opacity = math.max(0, 4 * page - 3);

    return Positioned(
      top: 128 + 400 + 32.0 + 16 + 32 + 40,
      width: MediaQuery.of(context).size.width,
      child: Opacity(
        opacity: opacity,
        child: MapHider(
          child: Center(
            child: Text(
              '72 km',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HorizontalTravelDots extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    double spacingFactor;
    double opacity;
    if (animationValue == 1) {
      return Container();
    }
    if (animationValue == 0) {
      spacingFactor = math.max(0, 4 * page - 3);
      opacity = spacingFactor;
    } else {
      spacingFactor = math.max(0, 1 - 6 * animationValue);
      opacity = 1;
    }

    return Positioned(
      top: 128 + 400 + 32.0 + 16 + 32 + 4,
      left: 0,
      right: 0,
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: spacingFactor * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightGrey,
                ),
                height: 4,
                width: 4,
              ),
              Container(
                margin: EdgeInsets.only(right: spacingFactor * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightGrey,
                ),
                height: 4,
                width: 4,
              ),
              Container(
                margin: EdgeInsets.only(right: spacingFactor * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: white),
                ),
                height: 8,
                width: 8,
              ),
              Container(
                margin: EdgeInsets.only(left: spacingFactor * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: white,
                ),
                height: 8,
                width: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerticalTravelDots extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;
    var mapAnimationProvider = useProvider(mapAnimationNotifierProvider);
    var mapAnimationValue = useListenable(mapAnimationProvider).value;

    if (animationValue < 1 / 6 || mapAnimationValue > 0) {
      return Container();
    }

    double startTop = 128.0 + 400.0 + 32 + 16 + 32 + 4;
    double bottom = MediaQuery.of(context).size.height - startTop - 80 - 6;
    double endTop = 128.0 + 32;
    double top;

    top = endTop +
        (1 - (1.2 * (animationValue - 1 / 6))) * (400 + 32 + 16 + 8 - 4);
    double oneThird = (startTop - endTop) / 3;

    return Positioned(
      top: top,
      bottom: bottom,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 1,
            height: double.infinity,
            color: white,
          ),
          Positioned(
            top: top > oneThird + endTop ? 0 : oneThird + endTop - top,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mainBlack,
                border: Border.all(color: white, width: 2.5),
              ),
              height: 8,
              width: 8,
            ),
          ),
          Positioned(
            top: top > 2 * oneThird + endTop ? 0 : 2 * oneThird + endTop - top,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mainBlack,
                border: Border.all(color: white, width: 2.5),
              ),
              height: 8,
              width: 8,
            ),
          ),
          Align(
            alignment: Alignment(0, 1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: white, width: 1),
                color: mainBlack,
              ),
              height: 8,
              width: 8,
            ),
          ),
          Align(
            alignment: Alignment(0, -1),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: white,
              ),
              height: 8,
              width: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedRoute extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var mapAnimationProvider = useProvider(mapAnimationNotifierProvider);
    var animationValue = useListenable(mapAnimationProvider).value;

    if (animationValue == 0) {
      return Container();
    }

    double startTop = 128.0 + 400.0 + 32 + 16 + 32 + 4;
    double bottom = MediaQuery.of(context).size.height - startTop - 80 - 6;
    double endTop = 128.0 + 32;
    double width = MediaQuery.of(context).size.width;

    double oneThird = (startTop - endTop) / 3;

    return Positioned(
      top: endTop,
      bottom: bottom,
      left: 0,
      right: 0,
      child: CustomPaint(
        painter: CurvePainter(animationValue),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              top: oneThird,
              right: width / 2 - 4 - animationValue * 60,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mainBlack,
                  border: Border.all(color: white, width: 2.5),
                ),
                height: 8,
                width: 8,
              ),
            ),
            Positioned(
              top: 2 * oneThird,
              right: width / 2 - 4 - animationValue * 50,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mainBlack,
                  border: Border.all(color: white, width: 2.5),
                ),
                height: 8,
                width: 8,
              ),
            ),
            Align(
              alignment: Alignment(0, 1),
              child: Container(
                margin: EdgeInsets.only(right: 100 * animationValue),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: white, width: 1),
                  color: mainBlack,
                ),
                height: 8,
                width: 8,
              ),
            ),
            Align(
              alignment: Alignment(0, -1),
              child: Container(
                margin: EdgeInsets.only(left: 40 * animationValue),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: white,
                ),
                height: 8,
                width: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  final double animationValue;
  double width;

  CurvePainter(this.animationValue);

  double interpolate(double x) {
    return width / 2 + (x - width / 2) * animationValue;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    width = size.width;
    paint.color = white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    var path = Path();

//    print(interpolate(size, x))
    var startPoint = Offset(interpolate(width / 2 + 20), 4);
    var controlPoint1 = Offset(interpolate(width / 2 + 60), size.height / 4);
    var controlPoint2 = Offset(interpolate(width / 2 + 20), size.height / 4);
    var endPoint = Offset(interpolate(width / 2 + 55 + 4), size.height / 3);

    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
        controlPoint2.dy, endPoint.dx, endPoint.dy);

    startPoint = endPoint;
    controlPoint1 = Offset(interpolate(width / 2 + 100), size.height / 2);
    controlPoint2 = Offset(interpolate(width / 2 + 20), size.height / 2 + 40);
    endPoint = Offset(interpolate(width / 2 + 50 + 2), 2 * size.height / 3 - 1);

    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
        controlPoint2.dy, endPoint.dx, endPoint.dy);

    startPoint = endPoint;
    controlPoint1 =
        Offset(interpolate(width / 2 - 20), 2 * size.height / 3 - 10);
    controlPoint2 =
        Offset(interpolate(width / 2 + 20), 5 * size.height / 6 - 10);
    endPoint = Offset(interpolate(width / 2), 5 * size.height / 6 + 2);

    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
        controlPoint2.dy, endPoint.dx, endPoint.dy);

    startPoint = endPoint;
    controlPoint1 = Offset(interpolate(width / 2 - 100), size.height - 80);
    controlPoint2 = Offset(interpolate(width / 2 - 40), size.height - 50);
    endPoint = Offset(interpolate(width / 2 - 50), size.height - 4);

    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
        controlPoint2.dy, endPoint.dx, endPoint.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CurvePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class MapBaseCamp extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(mapAnimationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    double opacity = math.max(0, 4 * (animationValue - 3 / 4));

    return Positioned(
      top: 128.0 + 28,
      width: (MediaQuery.of(context).size.width - 48) / 3,
      right: 30.0,
      child: Opacity(
        opacity: opacity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Base camp',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class MapStartCamp extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(mapAnimationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    double opacity = math.max(0, 4 * (animationValue - 3 / 4));

    return Positioned(
      top: startTop - 4,
      width: (MediaQuery.of(context).size.width - 48) / 3,
      child: Opacity(
        opacity: opacity,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            'Start camp',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class MapLeopard extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(mapAnimationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    double opacity = math.max(0, 4 * (animationValue - 3 / 4));

    return Positioned(
      top: 128.0 + 28 + oneThird,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.only(left: 30),
          child: SmallAnimalIconLabel(
            isVulture: false,
            showLine: false,
          ),
        ),
      ),
    );
  }
}

class MapVultures extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(mapAnimationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    double opacity = math.max(0, 4 * (animationValue - 3 / 4));

    return Positioned(
      top: 128.0 + 28 + 2 * oneThird,
      right: 50,
      child: Opacity(
        opacity: opacity,
        child: SmallAnimalIconLabel(
          isVulture: true,
          showLine: false,
        ),
      ),
    );
  }
}

class VultureImage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var offset = useProvider(offsetProvider).state;
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    return Positioned(
      left: .6 * MediaQuery.of(context).size.width - 0.85 * offset,
      width: MediaQuery.of(context).size.width * 1.6,
      child: MapHider(
        child: IgnorePointer(
          child: Transform.scale(
            scale: 1 - .1 * animationValue,
            child: Opacity(
              opacity: 1 - .6 * animationValue,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 64),
                child: Image.asset(
                  'assets/vulture.png',
                  height: MediaQuery.of(context).size.height / 3.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ArrowIcon extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    return Positioned(
      top: 128 + (1 - animationValue) * (400 + 32.0 - 4),
      right: 24,
      child: MapHider(
        child: Icon(
          Icons.keyboard_arrow_up,
          size: 28,
          color: lighterGrey,
        ),
      ),
    );
  }
}

class VulturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: MapHider(
        child: VultureCircle(),
      ),
    );
  }
}

class AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Row(
          children: <Widget>[
            Text(
              'SY',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Spacer(),
            Icon(Icons.menu)
          ],
        ),
      ),
    );
  }
}

class PageIndicator extends HookWidget {
  final whiteToGrey = ColorTween(begin: white, end: lightGrey);
  final greyToWhite = ColorTween(begin: lightGrey, end: white);

  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;

    return MapHider(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: whiteToGrey.transform(page),
                ),
                height: 6,
                width: 6,
              ),
              SizedBox(
                width: 8,
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: greyToWhite.transform(page),
                ),
                height: 6,
                width: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VultureIconLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;
    var _mapAnimationProvider = useProvider(mapAnimationNotifierProvider);
    var mapAnimationValue = useListenable(_mapAnimationProvider).value;

    double startTop = 128.0 + 400.0 + 32 + 16 + 32 + 4;
    double endTop = 128.0 + 32;
    double oneThird = (startTop - endTop) / 3;
    double opacity;
    if (animationValue < 2 / 3) {
      opacity = 0;
    } else if (mapAnimationValue == 0) {
      opacity = 3 * (animationValue - 2 / 3);
    } else if (mapAnimationValue < .33) {
      opacity = 1 - 3 * mapAnimationValue;
    } else {
      opacity = 0;
    }

    return Positioned(
      top: endTop + 2 * oneThird - 28 - 16 - 7,
      right: 10 + opacity * 16,
      child: Opacity(
        opacity: opacity,
        child: SmallAnimalIconLabel(
          isVulture: true,
          showLine: true,
        ),
      ),
    );
  }
}

class LeopardIconLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;
    var _mapAnimationProvider = useProvider(mapAnimationNotifierProvider);
    var mapAnimationValue = useListenable(_mapAnimationProvider).value;

    double opacity;
    if (animationValue < 3 / 4) {
      opacity = 0;
    } else if (mapAnimationValue == 0) {
      opacity = 3 * (animationValue - 2 / 3);
    } else if (mapAnimationValue < .33) {
      opacity = 1 - 3 * mapAnimationValue;
    } else {
      opacity = 0;
    }

    return Positioned(
      top: endTop + oneThird - 28 - 16 - 7,
      left: 10 + opacity * 16,
      child: Opacity(
        opacity: opacity,
        child: SmallAnimalIconLabel(
          isVulture: false,
          showLine: true,
        ),
      ),
    );
  }
}

class SmallAnimalIconLabel extends StatelessWidget {
  final bool isVulture;
  final bool showLine;

  const SmallAnimalIconLabel({Key key, @required this.isVulture, this.showLine})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showLine && isVulture)
          Container(
            margin: EdgeInsets.only(bottom: 4),
            width: 16,
            height: 1,
            color: white,
          ),
        SizedBox(
          width: 24,
        ),
        Column(
          children: [
            Image.asset(
              isVulture ? 'assets/vultures.png' : 'assets/leopards.png',
              width: 28,
              height: 28,
            ),
            SizedBox(
              height: showLine ? 16 : 0,
            ),
            Text(
              isVulture ? 'Vulture' : 'Leopard',
              style: TextStyle(fontSize: showLine ? 14 : 12),
            )
          ],
        ),
        SizedBox(
          width: 24,
        ),
        if (showLine && !isVulture)
          Container(
            margin: EdgeInsets.only(bottom: 4),
            width: 16,
            height: 1,
            color: white,
          ),
      ],
    );
  }
}
