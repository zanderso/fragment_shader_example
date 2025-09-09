# fragment_shader_example

A simple example of a custom shader in a Flutter app.

The shader under `shaders/example.frag` computes a color for each pixel
that depends only on the position and the "time". The time is supplied as
a uniform to the shader, and so we can use a `CustomPainter` to animate it.

See https://docs.flutter.dev/ui/design/graphics/fragment-shaders details.
