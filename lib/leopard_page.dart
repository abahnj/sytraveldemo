import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'main_page.dart';
import 'styles.dart';

class LeopardPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 128,
        ),
        The72Number(),
        SizedBox(
          height: 32,
        ),
        TravelDescriptionLabel(),
        SizedBox(
          height: 32,
        ),
        LeopardDescriptionLabel(),
      ],
    );
  }
}

class ShareButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 24,
      child: Icon(Icons.share),
    );
  }
}

class TravelDescriptionLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    return Opacity(
      opacity: math.max(0, 1 - 4 * page),
      child: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Text(
          'Travel Description',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class LeopardDescriptionLabel extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var page = useProvider(pageProvider).state;
    return Opacity(
      opacity: math.max(0, 1 - 4 * page),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'The leopard is distinguished by its well-camouflaged fur, opportunistic hunting behaviour, broad diet, and strength.',
          style: TextStyle(color: lightGrey),
        ),
      ),
    );
  }
}

class The72Number extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var offset = useProvider(offsetProvider).state;
    return Transform.translate(
      offset: Offset(-50 - .4 * offset, 0),
      child: Container(
        alignment: Alignment.topLeft,
        child: RotatedBox(
          quarterTurns: 1,
          child: SizedBox(
            width: 400,
            child: FittedBox(
              alignment: Alignment.bottomCenter,
              fit: BoxFit.cover,
              child: Text(
                '72',
                style: TextStyle(
                  fontSize: 400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LeopardImage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    var offset = useProvider(offsetProvider).state;
    var _animationProvider = useProvider(animationNotifierProvider);
    var animationValue = useListenable(_animationProvider).value;

    return Positioned(
      left: -0.85 * offset,
      width: MediaQuery.of(context).size.width * 1.6,
      child: MapHider(
        child: IgnorePointer(
          child: Transform.scale(
            alignment: Alignment(.75, 0),
            scale: 1 - .1 * animationValue,
            child: Opacity(
              opacity: 1 - .6 * animationValue,
              child: Image.asset('assets/leopard.png'),
            ),
          ),
        ),
      ),
    );
  }
}
