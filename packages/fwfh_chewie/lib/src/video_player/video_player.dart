import 'package:chewie/chewie.dart' as lib;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as lib;

/// A video player.
class VideoPlayer extends StatelessWidget {
  /// The source URL.
  final String url;

  /// The initial aspect ratio.
  final double aspectRatio;

  /// Controls whether to resize automatically.
  ///
  /// Default: `true`.
  final bool autoResize;

  /// Controls whether to play video automatically.
  ///
  /// Default: `false`.
  final bool autoplay;

  /// Controls whether to show video controls.
  ///
  /// Default: `false`.
  final bool controls;

  /// Controls whether to play video in loops.
  ///
  /// Default: `false`.
  final bool loop;

  /// The widget to be shown before video is loaded.
  final Widget? poster;

  final Key? _key;

  /// Creates a player.
  VideoPlayer(
    this.url, {
    required this.aspectRatio,
    this.autoResize = true,
    this.autoplay = false,
    this.controls = false,
    Key? key,
    this.loop = false,
    this.poster,
  }) : _key = key;

  @override
  Widget build(BuildContext context) => _VideoPlayerWidget(
        config: this,
        key: _key,
        platform: Theme.of(context).platform,
      );
}

class _VideoPlayerWidget extends StatefulWidget {
  final VideoPlayer config;

  final TargetPlatform platform;

  const _VideoPlayerWidget({
    required this.config,
    Key? key,
    required this.platform,
  }) : super(key: key);

  @override
  State<_VideoPlayerWidget> createState() =>
      platform == TargetPlatform.android ||
              platform == TargetPlatform.iOS ||
              kIsWeb
          ? _VideoPlayerState()
          : _PlaceholderState();
}

class _VideoPlayerState extends State<_VideoPlayerWidget> {
  late lib.ChewieController _controller;

  VideoPlayer get config => widget.config;

  @override
  void initState() {
    super.initState();
    _controller = _Controller(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: _controller.aspectRatio!,
        child: lib.Chewie(controller: _controller),
      );

  void _onAspectRatioUpdated() => setState(() {});
}

class _Controller extends lib.ChewieController {
  final _VideoPlayerState vps;

  double? _aspectRatio;

  _Controller(this.vps)
      : super(
          autoInitialize: true,
          autoPlay: vps.config.autoplay,
          looping: vps.config.loop,
          placeholder: vps.config.poster != null
              ? Center(child: vps.config.poster)
              : null,
          showControls: vps.config.controls,
          videoPlayerController:
              lib.VideoPlayerController.network(vps.config.url),
        ) {
    if (vps.config.autoResize) {
      _setupAspectRatioListener();
    }
  }

  @override
  double get aspectRatio => _aspectRatio ?? vps.config.aspectRatio;

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.dispose();
  }

  void _setupAspectRatioListener() {
    late VoidCallback listener;

    listener = () {
      if (_aspectRatio == null) {
        final vpv = videoPlayerController.value;
        if (!vpv.isInitialized) return;

        _aspectRatio = vpv.aspectRatio;
        vps._onAspectRatioUpdated();
      }

      videoPlayerController.removeListener(listener);
    };

    videoPlayerController.addListener(listener);
  }
}

class _PlaceholderState extends State<_VideoPlayerWidget> {
  @override
  Widget build(BuildContext _) => AspectRatio(
      aspectRatio: widget.config.aspectRatio,
      child: DecoratedBox(
        child: Center(child: Text('platform=${widget.platform}')),
        decoration: const BoxDecoration(color: Color.fromRGBO(0, 0, 0, .5)),
      ));
}
