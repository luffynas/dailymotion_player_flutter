import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../enums/player_state.dart';
import '../utils/dailymotion_meta_data.dart';
import '../utils/dailymotion_player_controller.dart';

class RawDailymotionPlayer extends StatefulWidget {
  /// Creates a [RawDailymotionPlayer] widget.
  const RawDailymotionPlayer({super.key, this.onEnded});

  /// {@macro dailymotion_player_flutter.onEnded}
  final void Function(DailymotionMetaData metaData)? onEnded;

  @override
  State<RawDailymotionPlayer> createState() => _RawDailymotionPlayerState();
}

class _RawDailymotionPlayerState extends State<RawDailymotionPlayer>
    with WidgetsBindingObserver {
  DailymotionPlayerController? controller;
  PlayerState? _cachedPlayerState;
  bool _isPlayerReady = false;
  bool _onLoadStopCalled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_cachedPlayerState != null &&
            _cachedPlayerState == PlayerState.playing) {
          controller?.play();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _cachedPlayerState = controller!.value.playerState;
        controller?.pause();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    controller = DailymotionPlayerController.of(context);
    return IgnorePointer(
      ignoring: true,
      child: InAppWebView(
        key: widget.key,
        initialData: InAppWebViewInitialData(
          data: player,
          baseUrl: Uri.parse('https://www.dailymotion.com'),
          encoding: 'utf-8',
          mimeType: 'text/html',
        ),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            userAgent: userAgent,
            mediaPlaybackRequiresUserGesture: false,
            transparentBackground: true,
            disableContextMenu: true,
            supportZoom: false,
            disableHorizontalScroll: false,
            disableVerticalScroll: false,
            useShouldOverrideUrlLoading: true,
          ),
          ios: IOSInAppWebViewOptions(
            allowsInlineMediaPlayback: true,
            allowsAirPlayForMediaPlayback: true,
            allowsPictureInPictureMediaPlayback: true,
          ),
          android: AndroidInAppWebViewOptions(
            useWideViewPort: false,
            useHybridComposition: controller!.flags.useHybridComposition,
          ),
        ),
        onWebViewCreated: (webController) {
          controller!.updateValue(
            controller!.value.copyWith(webViewController: webController),
          );
          webController
            ..addJavaScriptHandler(
              handlerName: 'Ready',
              callback: (_) {
                _isPlayerReady = true;
                if (_onLoadStopCalled) {
                  controller!.updateValue(
                    controller!.value.copyWith(isReady: true),
                  );
                }
              },
            )
            // ..addJavaScriptHandler(
            //   handlerName: 'StateChange',
            //   callback: (args) {
            //     log('message :: handlerName: StateChange, :: ${args.length}');
            //     switch (args.first as int) {
            //       case -1:
            //         controller!.updateValue(
            //           controller!.value.copyWith(
            //             playerState: PlayerState.unStarted,
            //             isLoaded: true,
            //           ),
            //         );
            //         break;
            //       case 0:
            //         widget.onEnded?.call(controller!.metadata);
            //         controller!.updateValue(
            //           controller!.value.copyWith(
            //             playerState: PlayerState.ended,
            //           ),
            //         );
            //         break;
            //       case 1:
            //         controller!.updateValue(
            //           controller!.value.copyWith(
            //             playerState: PlayerState.playing,
            //             isPlaying: true,
            //             hasPlayed: true,
            //             errorCode: 0,
            //           ),
            //         );
            //         break;
            //       case 2:
            //         controller!.updateValue(
            //           controller!.value.copyWith(
            //             playerState: PlayerState.paused,
            //             isPlaying: false,
            //           ),
            //         );
            //         break;
            //       case 3:
            //         controller!.updateValue(
            //           controller!.value.copyWith(
            //             playerState: PlayerState.buffering,
            //           ),
            //         );
            //         break;
            //       case 5:
            //         controller!.updateValue(
            //           controller!.value.copyWith(
            //             playerState: PlayerState.cued,
            //           ),
            //         );
            //         break;
            //       default:
            //         throw Exception("Invalid player state obtained.");
            //     }
            //   },
            // )
            ..addJavaScriptHandler(
              handlerName: 'PlaybackQualityChange',
              callback: (args) {
                controller!.updateValue(
                  controller!.value
                      .copyWith(playbackQuality: args.first as String),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'PlaybackRateChange',
              callback: (args) {
                final num rate = args.first;
                controller!.updateValue(
                  controller!.value.copyWith(playbackRate: rate.toDouble()),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'Errors',
              callback: (args) {
                controller!.updateValue(
                  controller!.value.copyWith(errorCode: int.parse(args.first)),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'VideoData',
              callback: (args) {
                controller!.updateValue(
                  controller!.value.copyWith(
                      metaData: DailymotionMetaData.fromRawData(args.first)),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'VideoTime',
              callback: (args) {
                final position = args.first * 1000;
                final num buffered = args.last;
                controller!.updateValue(
                  controller!.value.copyWith(
                    position: Duration(milliseconds: position.floor()),
                    buffered: buffered.toDouble(),
                  ),
                );
              },
            )
            //Test
            ..addJavaScriptHandler(
              handlerName: 'VideoEnd',
              callback: (args) {
                widget.onEnded?.call(controller!.metadata);
                controller!.updateValue(
                  controller!.value.copyWith(
                    playerState: PlayerState.unStarted,
                    isLoaded: true,
                    isPlaying: false,
                    hasPlayed: false,
                  ),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'Playing',
              callback: (args) {
                controller!.updateValue(
                  controller!.value.copyWith(
                    playerState: PlayerState.playing,
                    isPlaying: true,
                    hasPlayed: true,
                    errorCode: 0,
                  ),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'Buffering',
              callback: (args) {
                controller!.updateValue(
                  controller!.value.copyWith(
                    playerState: PlayerState.buffering,
                  ),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'Progress',
              callback: (args) {
                controller!.updateValue(
                  controller!.value.copyWith(
                    playerState: PlayerState.buffering,
                  ),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'VideoPause',
              callback: (args) {
                controller!.updateValue(
                  controller!.value.copyWith(
                    playerState: PlayerState.paused,
                    isPlaying: false,
                  ),
                );
              },
            );
        },
        onConsoleMessage: (controller, consoleMessage) {
          // onConsole from log javascript
        },
        onLoadStop: (_, __) {
          _onLoadStopCalled = true;
          if (_isPlayerReady) {
            controller!.updateValue(
              controller!.value.copyWith(isReady: true),
            );
          }
        },
      ),
    );
  }

  // String get player => '''
  //   <!DOCTYPE html>
  //   <html>
  //   <head>
  //       <style>
  //           html,
  //           body {
  //               margin: 0;
  //               padding: 0;
  //               background-color: #000000;
  //               overflow: hidden;
  //               position: fixed;
  //               height: 100%;
  //               width: 100%;
  //               pointer-events: none;
  //           }
  //       </style>
  //       <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
  //   </head>
  //   <body>
  //       <div id="player"></div>
  //       <script>
  //           var tag = document.createElement('script');
  //           tag.src = "https://www.youtube.com/iframe_api";
  //           var firstScriptTag = document.getElementsByTagName('script')[0];
  //           firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
  //           var player;
  //           var timerId;
  //           function onYouTubeIframeAPIReady() {
  //               player = new YT.Player('player', {
  //                   height: '100%',
  //                   width: '100%',
  //                   videoId: '${controller!.initialVideoId}',
  //                   playerVars: {
  //                       'controls': 0,
  //                       'playsinline': 1,
  //                       'enablejsapi': 1,
  //                       'fs': 0,
  //                       'rel': 0,
  //                       'showinfo': 0,
  //                       'iv_load_policy': 3,
  //                       'modestbranding': 1,
  //                       'cc_load_policy': ${boolean(value: controller!.flags.enableCaption)},
  //                       'cc_lang_pref': '${controller!.flags.captionLanguage}',
  //                       'autoplay': ${boolean(value: controller!.flags.autoPlay)},
  //                       'start': ${controller!.flags.startAt},
  //                       'end': ${controller!.flags.endAt}
  //                   },
  //                   events: {
  //                       onReady: function(event) { window.flutter_inappwebview.callHandler('Ready'); },
  //                       onStateChange: function(event) { sendPlayerStateChange(event.data); },
  //                       onPlaybackQualityChange: function(event) { window.flutter_inappwebview.callHandler('PlaybackQualityChange', event.data); },
  //                       onPlaybackRateChange: function(event) { window.flutter_inappwebview.callHandler('PlaybackRateChange', event.data); },
  //                       onError: function(error) { window.flutter_inappwebview.callHandler('Errors', error.data); }
  //                   },
  //               });
  //           }

  //           function sendPlayerStateChange(playerState) {
  //               clearTimeout(timerId);
  //               window.flutter_inappwebview.callHandler('StateChange', playerState);
  //               if (playerState == 1) {
  //                   startSendCurrentTimeInterval();
  //                   sendVideoData(player);
  //               }
  //           }

  //           function sendVideoData(player) {
  //               var videoData = {
  //                   'duration': player.getDuration(),
  //                   'title': player.getVideoData().title,
  //                   'author': player.getVideoData().author,
  //                   'videoId': player.getVideoData().video_id
  //               };
  //               window.flutter_inappwebview.callHandler('VideoData', videoData);
  //           }

  //           function startSendCurrentTimeInterval() {
  //               timerId = setInterval(function () {
  //                   window.flutter_inappwebview.callHandler('VideoTime', player.getCurrentTime(), player.getVideoLoadedFraction());
  //               }, 100);
  //           }

  //           function play() {
  //               player.playVideo();
  //               return '';
  //           }

  //           function pause() {
  //               player.pauseVideo();
  //               return '';
  //           }

  //           function loadById(loadSettings) {
  //               player.loadVideoById(loadSettings);
  //               return '';
  //           }

  //           function cueById(cueSettings) {
  //               player.cueVideoById(cueSettings);
  //               return '';
  //           }

  //           function loadPlaylist(playlist, index, startAt) {
  //               player.loadPlaylist(playlist, 'playlist', index, startAt);
  //               return '';
  //           }

  //           function cuePlaylist(playlist, index, startAt) {
  //               player.cuePlaylist(playlist, 'playlist', index, startAt);
  //               return '';
  //           }

  //           function mute() {
  //               player.mute();
  //               return '';
  //           }

  //           function unMute() {
  //               player.unMute();
  //               return '';
  //           }

  //           function setVolume(volume) {
  //               player.setVolume(volume);
  //               return '';
  //           }

  //           function seekTo(position, seekAhead) {
  //               player.seekTo(position, seekAhead);
  //               return '';
  //           }

  //           function setSize(width, height) {
  //               player.setSize(width, height);
  //               return '';
  //           }

  //           function setPlaybackRate(rate) {
  //               player.setPlaybackRate(rate);
  //               return '';
  //           }

  //           function setTopMargin(margin) {
  //               document.getElementById("player").style.marginTop = margin;
  //               return '';
  //           }
  //       </script>
  //   </body>
  //   </html>
  // ''';
  String get player => '''
      <html lang="en">
      <head>
        <meta name="viewport"
          content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
        <script>
            if(!document.__defineGetter__) {
                  Object.defineProperty(document, 'cookie', {
                      get: function(){return ''},
                      set: function(){return true},
                  });
              } else {
                  document.__defineGetter__("cookie", function() { return '';} );
                  document.__defineSetter__("cookie", function() {} );
              }
        </script>
      </head>
      <body> 
        <div id="playerArea"></div>
        <script src="https://geo.dailymotion.com/libs/player/${controller!.playerId}.js"></script>
        <script>
          var currentPlayer;
          var timerId;
          dailymotion
            .createPlayer("playerArea", {
              video: "${controller!.initialVideoId}",
              params: {
                startTime: ${controller!.flags.startAt},
                loop: false,
                mute: false,
                autoplay: ${boolean(value: controller!.flags.autoPlay)},

              },
            }).then(player => {
              currentPlayer = player

              player.on(dailymotion.events.PLAYER_CRITICALPATHREADY, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                window.flutter_inappwebview.callHandler('Ready');
                sendVideoData(result);
              }, { once: true })
            
              player.on(dailymotion.events.PLAYER_VOLUMECHANGE, (event) => {
                var message = JSON.stringify(event);
              })
            
              player.on(dailymotion.events.VIDEO_PLAY, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                sendPlayerStateChange(result);
                window.flutter_inappwebview.callHandler('VideoPlay');
              })
          
              player.on(dailymotion.events.VIDEO_BUFFERING, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                sendPlayerStateChange(result);
                window.flutter_inappwebview.callHandler('VideoBuffering');
              })
            
              player.on(dailymotion.events.VIDEO_DURATIONCHANGE, (event) => {
                var message = JSON.stringify(event);
                sendPlayerStateChange(message);
              })
            
              player.on(dailymotion.events.VIDEO_PAUSE, (event) => {
                var message = JSON.stringify(event);
                window.flutter_inappwebview.callHandler('VideoPause');
              })
            
              player.on(dailymotion.events.VIDEO_END, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                window.flutter_inappwebview.callHandler('VideoEnd', message);
              })
            
              player.on(dailymotion.events.VIDEO_PLAYING, (event) => {
                var message = JSON.stringify(event);
                window.flutter_inappwebview.callHandler('Playing', message);
              })
            
              player.on(dailymotion.events.VIDEO_PROGRESS, (event) => {
                var message = JSON.stringify(event);
                window.flutter_inappwebview.callHandler('Progress', message);
              })
            
              player.on(dailymotion.events.VIDEO_QUALITIESREADY, (event) => {
                var message = JSON.stringify(event);
                console.log('VIDEO_QUALITIESREADY '+message);
              })
            
              player.on(dailymotion.events.VIDEO_QUALITYCHANGE, (event) => {
                var message = JSON.stringify(event);
                console.log('VIDEO_QUALITYCHANGE '+message);
              })
            
              player.on(dailymotion.events.VIDEO_SEEKSTART, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message)
                sendPlayerStateChange(result);
              })
            
              player.on(dailymotion.events.VIDEO_SEEKEND, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                sendPlayerStateChange(result);
              })
            
              player.on(dailymotion.events.VIDEO_START, (event) => {
                var message = JSON.stringify(event);
              })
            
              player.on(dailymotion.events.VIDEO_TIMECHANGE, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                sendPlayerStateChange(result);
              })

              // AD EVENT
              player.on(dailymotion.events.AD_PLAY, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                sendPlayerStateChange(result);
              })
            
              player.on(dailymotion.events.AD_DURATIONCHANGE, (event) => {
                var message = JSON.stringify(event);
                sendPlayerStateChange(message);
              })
            
              player.on(dailymotion.events.AD_PAUSE, (event) => {
                var message = JSON.stringify(event);
                window.flutter_inappwebview.callHandler('VideoPause');
              })
            
              player.on(dailymotion.events.AD_END, (event) => {
                var message = JSON.stringify(event);
                var result = JSON.parse(message);
                window.flutter_inappwebview.callHandler('VideoEnd', message);
              })
            }).catch(error=> {
              alert(JSON.stringify(error))
            })

            function sendPlayerStateChange(playerState) {
              clearTimeout(timerId);
              window.flutter_inappwebview.callHandler('StateChange', playerState);
              if (playerState == 1) {
                  // startSendCurrentTimeInterval();
                  // sendVideoData(currentPlayer);
              }
              startSendCurrentTimeInterval(playerState);
            }

            function sendVideoData(player) {
              var videoData = {
                  'duration': player.videoDuration,
                  'title': player.videoTitle,
                  'author': player.videoOwnerUsername,
                  'videoId': player.videoId
              };
              window.flutter_inappwebview.callHandler('VideoData', videoData);
            }

            function startSendCurrentTimeInterval(playerState) {
              timerId = setInterval(function () {
                  window.flutter_inappwebview.callHandler('VideoTime', playerState.videoTime, playerState.videoDuration);
              }, 100);
            }

            function play() {
              currentPlayer.play()
            }

            function pause() {
              currentPlayer.pause()
            }

            function mute() {
              currentPlayer.setMuted(true);
              return '';
            }

            function unMute() {
              currentPlayer.setMuted(false);
              return '';
            }

            function setVolume(volume) {
              currentPlayer.setVolume(volume);
              return '';
            }

            function seekTo(position, seekAhead) {
              currentPlayer.seek(position);
              return '';
            }

            function fullScreen() {
              currentPlayer.setFullscreen(true)
              console.log('full screen')
            }

            function cancelFullScreen() {
              currentPlayer.setFullscreen(false)
            }
        </script>
        <style>
          body { margin: 0px; padding: 0px; height: 100%; overflow: hidden; }
          #playerArea { width: 100%; height: 100%; }
          .dailymotion-player { height: 100vh; }
        </style>
      </body>
      </html>
    ''';

  String boolean({required bool value}) => value == true ? "'1'" : "'0'";

  String get userAgent => controller!.flags.forceHD
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36'
      : '';
}
