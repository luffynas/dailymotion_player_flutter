import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../enums/player_state.dart';
import '../player/dailymotion_player_value.dart';
import 'dailymotion_meta_data.dart';
import 'dailymotion_player_flags.dart';
import 'inherited_dailymotion_player.dart';

class DailymotionPlayerController
    extends ValueNotifier<DailymotionPlayerValue> {
  /// The video id with which the player initializes.
  final String initialVideoId;

  /// palyer id
  final String playerId;

  /// Composes all the flags required to control the player.
  final DailymotionPlayerFlags flags;

  /// Creates [DailymotionPlayerController].
  DailymotionPlayerController({
    required this.initialVideoId,
    required this.playerId,
    this.flags = const DailymotionPlayerFlags(),
  }) : super(DailymotionPlayerValue());

  /// Finds [DailymotionPlayerController] in the provided context.
  static DailymotionPlayerController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedDailymotionPlayer>()
        ?.controller;
  }

  _callMethod(String methodString) {
    if (value.isReady) {
      value.webViewController?.evaluateJavascript(source: methodString);
    } else {
      print('The controller is not ready for method calls.');
    }
  }

  /// Updates the old [DailymotionPlayerValue] with new one provided.
  // ignore: use_setters_to_change_properties
  void updateValue(DailymotionPlayerValue newValue) => value = newValue;

  /// Plays the video.
  void play() => _callMethod('play()');

  /// Pauses the video.
  void pause() => _callMethod('pause()');

  /// Loads the video as per the [videoId] provided.
  void load(String videoId, {int startAt = 0, int? endAt}) {
    var loadParams = 'videoId:"$videoId",startSeconds:$startAt';
    if (endAt != null && endAt > startAt) {
      loadParams += ',endSeconds:$endAt';
    }
    _updateValues(videoId);
    if (value.errorCode == 1) {
      pause();
    } else {
      _callMethod('loadById({$loadParams})');
    }
  }

  /// Cues the video as per the [videoId] provided.
  void cue(String videoId, {int startAt = 0, int? endAt}) {
    var cueParams = 'videoId:"$videoId",startSeconds:$startAt';
    if (endAt != null && endAt > startAt) {
      cueParams += ',endSeconds:$endAt';
    }
    _updateValues(videoId);
    if (value.errorCode == 1) {
      pause();
    } else {
      _callMethod('cueById({$cueParams})');
    }
  }

  void _updateValues(String id) {
    if (id.length != 11) {
      updateValue(
        value.copyWith(
          errorCode: 1,
        ),
      );
      return;
    }
    updateValue(
      value.copyWith(errorCode: 0, hasPlayed: false),
    );
  }

  /// Mutes the player.
  void mute() => _callMethod('mute()');

  /// Un mutes the player.
  void unMute() => _callMethod('unMute()');

  /// Sets the volume of player.
  /// Max = 100 , Min = 0
  void setVolume(int volume) => volume >= 0 && volume <= 100
      ? _callMethod('setVolume($volume)')
      : throw Exception("Volume should be between 0 and 100");

  /// Seek to any position. Video auto plays after seeking.
  /// The optional allowSeekAhead parameter determines whether the player will make a new request to the server
  /// if the seconds parameter specifies a time outside of the currently buffered video data.
  /// Default allowSeekAhead = true
  void seekTo(Duration position, {bool allowSeekAhead = true}) {
    _callMethod('seekTo(${position.inMilliseconds / 1000},$allowSeekAhead)');
    play();
    updateValue(value.copyWith(position: position));
  }

  /// Sets the size in pixels of the player.
  void setSize(Size size) =>
      _callMethod('setSize(${size.width}, ${size.height})');

  /// Fits the video to screen width.
  void fitWidth(Size screenSize) {
    var adjustedHeight = 9 / 16 * screenSize.width;
    setSize(Size(screenSize.width, adjustedHeight));
    _callMethod(
      'setTopMargin("-${((adjustedHeight - screenSize.height) / 2 * 100).abs()}px")',
    );
  }

  /// Fits the video to screen height.
  void fitHeight(Size screenSize) {
    setSize(screenSize);
    _callMethod('setTopMargin("0px")');
  }

  /// Sets the playback speed for the video.
  void setPlaybackRate(double rate) => _callMethod('setPlaybackRate($rate)');

  /// Toggles the player's full screen mode.
  void toggleFullScreenMode() {
    log('message ::: value.isFullScreen ${value.isFullScreen}');
    updateValue(value.copyWith(isFullScreen: !value.isFullScreen));
    if (value.isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  /// MetaData for the currently loaded or cued video.
  DailymotionMetaData get metadata => value.metaData;

  /// Reloads the player.
  ///
  /// The video id will reset to [initialVideoId] after reload.
  void reload() => value.webViewController?.reload();

  /// Resets the value of [DailymotionPlayerController].
  void reset() => updateValue(
        value.copyWith(
          isReady: false,
          isFullScreen: false,
          isControlsVisible: false,
          playerState: PlayerState.unknown,
          hasPlayed: false,
          position: Duration.zero,
          buffered: 0.0,
          errorCode: 0,
          isLoaded: false,
          isPlaying: false,
          isDragging: false,
          metaData: const DailymotionMetaData(),
        ),
      );
}
