import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'game/character_liveliness.dart';

/// 승인 초상 한 장을 격자 메시로 그려 부위별로 다르게 움직인다.
///
/// 이미지 전체를 통째로 옮기는 `Transform`과 달리 정점마다 변위를 주므로, 리깅 없이도
/// 치맛단은 나팔거리고 머리끝은 늦게 따라오고 얼굴은 거의 멈춰 있다. 변위 규칙과 상한은
/// `game/character_liveliness.dart`가 정하고 여기서는 그리기만 한다.
///
/// 드로우콜은 격자 크기와 무관하게 1개다. 이미지를 로드하는 동안에는 정지 이미지를 쓴다.
///
/// 시간은 부모가 [seconds]로 넘긴다. 여기서 티커를 직접 돌리면 프레임이 끝없이 예약되어
/// 위젯 테스트의 `pumpAndSettle`이 영구히 정착하지 못한다. 로비는 짧게 재생하고 쉬는
/// 간헐 리듬을 이미 갖고 있으므로 그 시계를 그대로 쓴다.
class CharacterLivelinessView extends StatefulWidget {
  const CharacterLivelinessView({
    super.key,
    required this.asset,
    required this.seed,
    required this.seconds,
    this.columns = 8,
    this.rows = 20,
    this.intensity = 1,
    this.timing = const CharacterLivelinessTiming(),
    this.weights = const CharacterRegionWeights(),
    this.bands = const CharacterRegionBands(),
    this.limits = const CharacterLivelinessLimits(),
  });

  final String asset;

  /// 인물 구분자. 위상을 갈라 여러 명이 동기화되지 않게 한다.
  final String seed;

  /// 모션이 진행된 누적 시간(초). 부모가 재생 구간에서만 늘려 준다.
  final double seconds;

  final int columns;
  final int rows;

  /// 0이면 완전히 멈춘다.
  final double intensity;

  final CharacterLivelinessTiming timing;
  final CharacterRegionWeights weights;
  final CharacterRegionBands bands;
  final CharacterLivelinessLimits limits;

  @override
  State<CharacterLivelinessView> createState() =>
      _CharacterLivelinessViewState();
}

class _CharacterLivelinessViewState extends State<CharacterLivelinessView> {
  ui.Image? _image;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(CharacterLivelinessView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _image = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    final provider = AssetImage(widget.asset);
    final configuration = createLocalImageConfiguration(context);
    final stream = provider.resolve(configuration);
    if (stream.key == _stream?.key) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    final listener = ImageStreamListener((info, _) {
      if (!mounted) {
        info.dispose();
        return;
      }
      setState(() => _image = info.image);
    }, onError: (_, _) {});
    _stream = stream..addListener(listener);
    _listener = listener;
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      // 로드 전에는 정지 이미지를 보여 준다. 빈 화면을 두지 않는다.
      return Image.asset(
        widget.asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      );
    }
    // 접근성 설정에서 애니메이션을 끄면 완전히 정지한다.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return RepaintBoundary(
      child: CustomPaint(
        key: const Key('character-liveliness-mesh'),
        painter: CharacterLivelinessPainter(
          image: image,
          seconds: widget.seconds,
          seed: widget.seed,
          columns: widget.columns,
          rows: widget.rows,
          intensity: reduceMotion ? 0 : widget.intensity,
          timing: widget.timing,
          weights: widget.weights,
          bands: widget.bands,
          limits: widget.limits,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// 격자 메시로 초상을 그린다. 정점 변위는 `characterVertexOffset`이 정한다.
class CharacterLivelinessPainter extends CustomPainter {
  CharacterLivelinessPainter({
    required this.image,
    required this.seconds,
    required this.seed,
    this.columns = 8,
    this.rows = 20,
    this.intensity = 1,
    this.timing = const CharacterLivelinessTiming(),
    this.weights = const CharacterRegionWeights(),
    this.bands = const CharacterRegionBands(),
    this.limits = const CharacterLivelinessLimits(),
  });

  final ui.Image image;
  final double seconds;
  final String seed;
  final int columns;
  final int rows;
  final double intensity;
  final CharacterLivelinessTiming timing;
  final CharacterRegionWeights weights;
  final CharacterRegionBands bands;
  final CharacterLivelinessLimits limits;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cols = math.max(2, columns);
    final rowCount = math.max(2, rows);
    final vertexCount = (cols + 1) * (rowCount + 1);

    final positions = Float32List(vertexCount * 2);
    final textures = Float32List(vertexCount * 2);
    var cursor = 0;
    for (var row = 0; row <= rowCount; row += 1) {
      final ny = row / rowCount;
      for (var col = 0; col <= cols; col += 1) {
        final nx = col / cols;
        final offset = characterVertexOffset(
          normalizedX: nx,
          normalizedY: ny,
          seconds: seconds,
          seed: seed,
          timing: timing,
          weights: weights,
          bands: bands,
          limits: limits,
          intensity: intensity,
        );
        positions[cursor] = nx * size.width + offset.dx;
        positions[cursor + 1] = ny * size.height + offset.dy;
        // 텍스처 좌표는 이미지 픽셀 공간이다.
        textures[cursor] = nx * image.width;
        textures[cursor + 1] = ny * image.height;
        cursor += 2;
      }
    }

    final indices = Uint16List(cols * rowCount * 6);
    var index = 0;
    for (var row = 0; row < rowCount; row += 1) {
      for (var col = 0; col < cols; col += 1) {
        final topLeft = row * (cols + 1) + col;
        final topRight = topLeft + 1;
        final bottomLeft = topLeft + cols + 1;
        final bottomRight = bottomLeft + 1;
        indices[index] = topLeft;
        indices[index + 1] = topRight;
        indices[index + 2] = bottomLeft;
        indices[index + 3] = topRight;
        indices[index + 4] = bottomRight;
        indices[index + 5] = bottomLeft;
        index += 6;
      }
    }

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.high,
      );
    final vertices = ui.Vertices.raw(
      VertexMode.triangles,
      positions,
      textureCoordinates: textures,
      indices: indices,
    );
    // srcOver로 그려 투명 배경을 유지한다.
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
    paint.shader?.dispose();
  }

  @override
  bool shouldRepaint(CharacterLivelinessPainter oldDelegate) =>
      oldDelegate.seconds != seconds ||
      oldDelegate.image != image ||
      oldDelegate.seed != seed ||
      oldDelegate.intensity != intensity ||
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows;
}
