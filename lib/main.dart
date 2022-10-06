// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is an example app showing how to load assets listed in the
// 'shader' section of the 'flutter' manifest in the pubspec.yaml file.
// A shader asset is loaded as a [FragmentProgram] object using the
// `FragmentProgram.fromAsset()` method. Then, [Shader] objects can be obtained
// by passing uniform values to the `FragmentProgram.shader()` method.
// The animation of a shader can be driven by passing the value of a Flutter
// [Animation] as one of the float uniforms of the shader program. In this
// example, the value of the animation is expected to be passed as the
// float uniform at index 0.
//
// The changes in https://github.com/flutter/engine/pull/35253 are a
// breaking change to the [FragmentProgram] API. The compensating changes are
// noted below as `TODO` items. The API is changing to allow re-using
// the float uniform buffer between frames.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// A standard Material application container, like you'd get from Flutter's
/// "Hello, world!" example.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shader Example',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Shader Example Home Page'),
    );
  }
}

/// The body of the app. We'll use this stateful widget to manage initialization
/// of the shader program.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _futuresInitialized = false;

  static const String _shaderKey = 'shaders/example.frag';

  Future<void> _initializeFutures() async {
    // Loading the shader from an asset is an asynchronous operation, so we
    // need to wait for it to be loaded before we can use it to generate
    // Shader objects.
    await FragmentProgramManager.initialize(_shaderKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _futuresInitialized = true;
    });
  }

  @override
  void initState() {
    _initializeFutures();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_futuresInitialized)
              AnimatedShader(
                program: FragmentProgramManager.lookup(_shaderKey),
                duration: const Duration(seconds: 2),
                size: const Size(300, 300),
              )
            else
              const Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

/// A custom painter that updates the float uniform at index 0 with the
/// current animation value and uses the shader to configure the Paint
/// object that draws a rectangle onto the canvas.
class AnimatedShaderPainter extends CustomPainter {
  AnimatedShaderPainter(this.shader, this.animation) : super(repaint: animation);

  final ui.FragmentShader shader;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, animation.value);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// This widget drives the animation of the AnimatedProgramPainter above.
class AnimatedShader extends StatefulWidget {
  const AnimatedShader({
    super.key,
    required this.program,
    required this.duration,
    required this.size,
  });

  final ui.FragmentProgram program;
  final Duration duration;
  final Size size;

  @override
  State<AnimatedShader> createState() => AnimatedShaderState();
}

class AnimatedShaderState extends State<AnimatedShader>
                          with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final ui.FragmentShader _shader;

  @override
  void initState() {
    super.initState();
    // TODO(zanderso): Initialize the shader after
    // https://github.com/flutter/engine/pull/35253 lands.
    _shader = widget.program.fragmentShader()
      ..setFloat(0, 0.0)
      ..setFloat(1, widget.size.width.toDouble())
      ..setFloat(2, widget.size.height.toDouble());
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
    ..addListener(() {
      setState(() {});
    })
    ..addStatusListener((AnimationStatus status) {
      switch (status) {
        case AnimationStatus.completed:
          _controller.reverse();
          break;
        case AnimationStatus.dismissed:
          _controller.forward();
          break;
        default:
          break;
      }
    })
    ..forward();
  }

  @override
  void didUpdateWidget(AnimatedShader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AnimatedShaderPainter(_shader, _controller),
      size: widget.size,
    );
  }
}

/// A utility class for initializing shader programs from asset keys.
class FragmentProgramManager {
  static final Map<String, ui.FragmentProgram> _programs = <String, ui.FragmentProgram>{};

  static Future<void> initialize(String assetKey) async {
    if (!_programs.containsKey(assetKey)) {
      final ui.FragmentProgram program = await ui.FragmentProgram.fromAsset(
        assetKey,
      );
      _programs.putIfAbsent(assetKey, () => program);
    }
  }

  static ui.FragmentProgram lookup(String assetKey) => _programs[assetKey]!;
}
