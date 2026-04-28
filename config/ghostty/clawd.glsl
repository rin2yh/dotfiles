// Clawd — the Claude Code mascot, rendered as a tiny corner companion.
//
// Designed for Ghostty's `custom-shader` (Shadertoy-style API). The shader
// composites over the terminal output in `iChannel0`; outside of Clawd's
// small bounding region the terminal is passed through untouched.
//
// Body palette mirrors Claude Code's `clawd_body` and `chromeYellow`
// theme tokens (rgb(215,119,87) and rgb(251,188,4)).

const vec3 BODY = vec3(215.0, 119.0,  87.0) / 255.0;
const vec3 WARN = vec3(251.0, 188.0,   4.0) / 255.0;

// Anchor point (in pixels, from bottom-right) and unit-scale for Clawd's
// local coordinate system. One "clawd unit" = SCALE pixels.
const vec2  ANCHOR_FROM_BR = vec2(110.0, 110.0);
const float SCALE          = 220.0;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float sdCircle(vec2 p, float r) { return length(p) - r; }

float sdSegment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

// Approximation of the ✻ sparkle: mixes Chebyshev and 45°-rotated norms.
float sdSparkle(vec2 p, float r) {
  p = abs(p);
  float a = max(p.x, p.y);
  float b = (p.x + p.y) * 0.7071;
  return mix(a, b, 0.6) - r;
}

float opSmoothUnion(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

mat2 rot2(float a) {
  float c = cos(a), s = sin(a);
  return mat2(c, -s, s, c);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec4 term = texture(iChannel0, fragCoord / iResolution.xy);

  // Anchor Clawd to the bottom-right corner. Local coords: ~±0.3 around 0.
  vec2 anchor = vec2(iResolution.x - ANCHOR_FROM_BR.x, ANCHOR_FROM_BR.y);
  vec2 cuv    = (fragCoord - anchor) / SCALE;

  // Cheap bounding-box reject: outside ~0.5 units there's nothing to draw,
  // so skip every SDF evaluation on the rest of the terminal.
  if (max(abs(cuv.x), abs(cuv.y)) > 0.55) {
    fragColor = term;
    return;
  }

  float t = iTime;

  float bounce = abs(sin(t * 2.6)) * 0.045;
  float tilt   = sin(t * 1.2) * 0.06;
  float breath = 1.0 + 0.025 * sin(t * 2.6 - 0.6);

  // Lift a bit so the antenna has room above the body.
  vec2 buv = cuv;
  buv.y -= bounce - 0.02;
  buv = rot2(tilt) * buv;
  buv /= breath;

  float dLower = sdRoundBox(buv - vec2(0.0, -0.05), vec2(0.225, 0.07), 0.05);
  float dUpper = sdRoundBox(buv - vec2(0.0,  0.05), vec2(0.18,  0.07), 0.05);
  float dBody  = opSmoothUnion(dLower, dUpper, 0.04);

  float dCap = sdRoundBox(buv - vec2(0.0, 0.16), vec2(0.07, 0.035), 0.025);
  dBody      = opSmoothUnion(dBody, dCap, 0.04);

  // Four feet (▘▘ ▝▝) mirrored around x=0 with a gap in the middle.
  vec2 footUV = vec2(abs(buv.x), buv.y + 0.135);
  float dFeet = min(
    sdRoundBox(footUV - vec2(0.04, 0.0), vec2(0.018, 0.022), 0.012),
    sdRoundBox(footUV - vec2(0.11, 0.0), vec2(0.018, 0.022), 0.012)
  );
  dBody = opSmoothUnion(dBody, dFeet, 0.012);

  float bodyMask  = smoothstep(0.005, -0.001, dBody);
  vec3  bodyShade = BODY * (0.85 + 0.25 * smoothstep(-0.18, 0.18, buv.y));
  float hl = smoothstep(0.12, 0.0, length(buv - vec2(-0.06, 0.10)));
  bodyShade += vec3(0.18, 0.10, 0.06) * hl;

  // Hollow inset matching ▛███▜ / █████ in the terminal art — fills with
  // black so eyes read against it.
  float dInner    = sdRoundBox(buv, vec2(0.165, 0.10), 0.04);
  float innerMask = smoothstep(0.003, -0.003, dInner) * bodyMask;
  vec3  bodyCol   = mix(bodyShade, vec3(0.0), innerMask * 0.92);

  // Eyes only contribute inside the hollow inset; gate the whole block on
  // innerMask to skip blink + look + two SDFs on the rest of the screen.
  if (innerMask > 0.0) {
    float blinkPhase = fract(t * 0.28);
    float blink = smoothstep(0.0, 0.04, blinkPhase) *
                  (1.0 - smoothstep(0.94, 1.0, blinkPhase));
    vec2 eyeL = buv - vec2(-0.055, 0.015);
    vec2 eyeR = buv - vec2( 0.055, 0.015);
    vec2 look = vec2(sin(t * 0.7) * 0.008, cos(t * 0.9) * 0.004);
    float eyeMask = smoothstep(0.003, 0.0,
      min(sdCircle(eyeL, 0.018), sdCircle(eyeR, 0.018)));
    bodyCol = mix(bodyCol, vec3(1.0, 0.96, 0.92), eyeMask * blink * innerMask);

    float pupMask = smoothstep(0.002, 0.0,
      min(sdCircle(eyeL - look, 0.009), sdCircle(eyeR - look, 0.009)));
    bodyCol = mix(bodyCol, vec3(0.04, 0.02, 0.0), pupMask * blink * innerMask);
  }

  // Antenna line + ✻ sparkle on top.
  float dLine = sdSegment(buv, vec2(0.0, 0.205), vec2(0.0, 0.255)) - 0.006;
  float lineMask = smoothstep(0.004, 0.0, dLine);

  vec2  sp     = rot2(t * 0.9) * (buv - vec2(0.0, 0.295));
  float pulse  = 0.025 + 0.005 * sin(t * 4.0);
  float dSp    = sdSparkle(sp, pulse);
  float spMask = smoothstep(0.006, 0.0, dSp);
  float spGlow = smoothstep(0.06, 0.0, dSp) * 0.45;

  // Compose Clawd's RGBA: body + antenna line + sparkle (with glow halo).
  vec3 clawdCol = bodyCol;
  clawdCol = mix(clawdCol, WARN * 0.55, lineMask);
  clawdCol = mix(clawdCol, WARN, spMask);

  float clawdA = clamp(bodyMask + lineMask + spMask, 0.0, 1.0);

  // Composite over the terminal; sparkle glow adds light on top.
  vec3 outCol = mix(term.rgb, clawdCol, clawdA);
  outCol += WARN * spGlow;

  fragColor = vec4(outCol, term.a);
}
