#version 460 core
precision highp float;

// Uniform order is load-bearing: Dart sets these by flat float index via
// FragmentShader.setFloat(0..9), in exactly this declaration order.
// sampler2D uniforms are bound separately via setImageSampler and must be
// declared last.
uniform vec2 uResolution;  // 0,1 - canvas size in physical pixels
uniform vec2 uImageSize;   // 2,3 - natural size of the source images
uniform float uProgress;   // 4   - spring-eased 0..1 hover progress
uniform float uTime;       // 5   - seconds, drives the noise animation
uniform vec2 uOrigin;      // 6,7 - pointer entry point, UV space (0..1)
uniform vec2 uDirection;   // 8,9 - wipe direction, normalized

uniform sampler2D uTexA;
uniform sampler2D uTexB;

out vec4 fragColor;

vec2 coverUv(vec2 uv) {
  vec2 ratio = vec2(
    min((uResolution.x / uResolution.y) / (uImageSize.x / uImageSize.y), 1.0),
    min((uResolution.y / uResolution.x) / (uImageSize.y / uImageSize.x), 1.0)
  );
  return vec2(
    uv.x * ratio.x + (1.0 - ratio.x) * 0.5,
    uv.y * ratio.y + (1.0 - ratio.y) * 0.5
  );
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

void main() {
  // FlutterFragCoord() origin is top-left; the original web canvas UV is
  // bottom-up, so flip Y to match the ported direction/origin math.
  vec2 uv = FlutterFragCoord().xy / uResolution;
  uv.y = 1.0 - uv.y;

  float p = uProgress;
  float bell = 4.0 * p * (1.0 - p);

  vec2 dir = normalize(uDirection + vec2(0.0001));
  float along = dot(uv - uOrigin, dir);
  float distGradient = (along + 1.4) / 2.8;

  float warpLow = fbm(uv * 1.8 + uTime * 0.05) - 0.5;
  float warpHi = fbm(uv * 5.5 - uTime * 0.04 + 13.0) - 0.5;
  float warp = warpLow * 0.55 + warpHi * 0.18;

  float field = distGradient + warp;

  float remapped = mix(-0.25, 1.25, p);
  float edgeWidth = 0.07;
  float mask = smoothstep(remapped - edgeWidth, remapped + edgeWidth, field);
  mask = 1.0 - mask;

  vec2 perp = vec2(-dir.y, dir.x);
  float ripplePhase = (field - remapped) * 14.0;
  float ripple = sin(ripplePhase) * 0.5 + 0.5;
  float edgeBand = 1.0 - smoothstep(0.0, edgeWidth * 1.6, abs(field - remapped));
  float pushAmount = ripple * edgeBand * 0.025 * bell;
  vec2 pushUv = uv + perp * pushAmount;

  vec4 texA = texture(uTexA, coverUv(pushUv));
  vec4 texB = texture(uTexB, coverUv(pushUv));

  vec4 color = mix(texA, texB, mask);
  color.rgb *= 1.0 - (edgeBand * 0.35 * bell);

  fragColor = color;
}
