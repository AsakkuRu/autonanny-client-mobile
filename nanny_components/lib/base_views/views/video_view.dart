import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';

class VideoView extends StatefulWidget {
  final String url;

  const VideoView({
    super.key,
    required this.url,
  });

  @override
  State<VideoView> createState() => _VideoViewState();
}

/// Inline превью видео-визитки для профиля водителя (автозапуск выключен).
class DriverVideoPreview extends StatefulWidget {
  const DriverVideoPreview({
    super.key,
    required this.videoUrl,
    this.height = 180,
  });

  final String videoUrl;
  final double height;

  @override
  State<DriverVideoPreview> createState() => _DriverVideoPreviewState();
}

class _DriverVideoPreviewState extends State<DriverVideoPreview> {
  BetterPlayerController? _controller;
  bool _hasError = false;

  // Файл отдается публично через `/api/v1.0/files/...`, Authorization может ломать загрузку.
  Map<String, String> _headers() => const {};

  @override
  void initState() {
    super.initState();

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.videoUrl,
      headers: _headers(),
    );

    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fit: BoxFit.cover,
      ),
      betterPlayerDataSource: dataSource,
    );

    _controller!.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controller == null) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Icon(Icons.videocam_off)),
      );
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BetterPlayer(controller: _controller!),
      ),
    );
  }
}

class _VideoViewState extends State<VideoView> {
  BetterPlayerController? _controller;
  String? _error;

  // Файл отдается публично через `/api/v1.0/files/...`, Authorization может ломать загрузку.
  Map<String, String> _headers() => const {};

  @override
  void initState() {
    super.initState();

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.url,
      headers: _headers(),
    );

    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fit: BoxFit.contain,
      ),
      betterPlayerDataSource: dataSource,
    );

    controller.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        dev.log(
          'BetterPlayer exception: ${event.parameters}',
          name: 'AutoNannyVideo',
        );
        if (mounted) {
          setState(() => _error = 'Не удалось загрузить видео');
        }
      }
    });

    _controller = controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: const NannyAppBar(),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            : _controller == null
                ? const Center(child: CircularProgressIndicator())
                : BetterPlayer(controller: _controller!),
      ),
    );
  }
}