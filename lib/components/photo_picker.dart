import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum PhotoPickerType {

  url,

  file,
}

class PhotoPicker extends StatefulWidget {
  File imageFile;
  String imageUrl;
  PhotoPickerType photoPickerType;

  PhotoPicker(this.photoPickerType, {this.imageFile, this.imageUrl});
  @override
  State<StatefulWidget> createState() {
    return PhotoPickerState();
  }
}

class PhotoPickerState extends State<PhotoPicker> with SingleTickerProviderStateMixin {
  BuildContext _context;
  AnimationController _controller;
  Animation<Offset> _animation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset;
  double _previousScale;
  double _kMinFlingVelocity = 600.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() {
        _offset = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Offset _clampOffset(Offset offset) {
    final Size size = context.size;
    // widget的屏幕宽度
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    // 限制他的最小尺寸
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // 计算图片放大后的位置
      _controller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 3.0);
      // 限制放大倍数 1~3倍
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
      // 更新当前位置
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    // 计算当前的方向
    final double distance = (Offset.zero & context.size).shortestSide;
    // 计算放大倍速，并相应的放大宽和高，比如原来是600*480的图片，放大后倍数为1.25倍时，宽和高是同时变化的
    _animation = _controller.drive(Tween<Offset>(
        begin: _offset, end: _clampOffset(_offset + direction * distance)));
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void _back() {
    Navigator.of(_context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    Widget imageView;
    if (widget.photoPickerType == PhotoPickerType.file) {
      imageView = Image.file(widget.imageFile, fit: BoxFit.fitWidth);
    } else if (widget.photoPickerType == PhotoPickerType.url) {
      imageView = CachedNetworkImage(imageUrl: widget.imageUrl, fit: BoxFit.fitWidth);
    }
    return Container(
      color: Colors.black,
      child: GestureDetector(
        onScaleStart: _handleOnScaleStart,
        onScaleUpdate: _handleOnScaleUpdate,
        onScaleEnd: _handleOnScaleEnd,
        onTap: _back,
        child: ClipRect(
          child: Transform(
            transform: Matrix4.identity()
              ..translate(_offset.dx, _offset.dy)
              ..scale(_scale),
            child: imageView,
          ),
        ),
      ),
    );
  }
}