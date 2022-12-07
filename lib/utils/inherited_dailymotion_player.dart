import 'package:flutter/material.dart';

import 'dailymotion_player_controller.dart';

/// An inherited widget to provide [DailymotionPlayerController] to it's descendants.
class InheritedDailymotionPlayer extends InheritedWidget {
  /// Creates [InheritedDailymotionPlayer]
  const InheritedDailymotionPlayer({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  /// A [DailymotionPlayerController] which controls the player.
  final DailymotionPlayerController controller;

  @override
  bool updateShouldNotify(InheritedDailymotionPlayer oldPlayer) =>
      oldPlayer.controller.hashCode != controller.hashCode;
}
