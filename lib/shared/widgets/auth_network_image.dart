import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_provider.dart';

/// Loads `/files/{id}/content` with the shared authenticated Dio client.
class AuthNetworkImage extends ConsumerStatefulWidget {
  const AuthNetworkImage({
    super.key,
    required this.fileId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String fileId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  ConsumerState<AuthNetworkImage> createState() => _AuthNetworkImageState();
}

class _AuthNetworkImageState extends ConsumerState<AuthNetworkImage> {
  Future<Uint8List>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _load();
  }

  @override
  void didUpdateWidget(covariant AuthNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileId != widget.fileId) {
      _bytesFuture = _load();
    }
  }

  Future<Uint8List> _load() async {
    final dio = await ref.read(dioReadyProvider.future);
    final response = await dio.get<List<int>>(
      ApiEndpoints.fileContent(widget.fileId),
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('empty image body');
    }
    return Uint8List.fromList(data);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.outline,
            ),
          );
        }
        final img = Image.memory(
          snap.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
        );
        if (widget.borderRadius != null) {
          return ClipRRect(borderRadius: widget.borderRadius!, child: img);
        }
        return img;
      },
    );
  }
}
