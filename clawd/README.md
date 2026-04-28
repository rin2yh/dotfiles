# Clawd — GLSL animation

A small WebGL2 / GLSL animation of **Clawd**, the Claude Code mascot.

The character is rendered procedurally with signed distance fields and is
modelled directly on the ASCII art Claude Code prints to the terminal:

```
   ▟█▙
  ▐▛███▜▌
  ▝▜█████▛▘
   ▘▘ ▝▝
```

…with the warning-coloured `✻ │` sparkle and antenna sitting on top.

The body color matches `clawd_body` (`rgb(215, 119, 87)`) and the inner
hollow matches `clawd_background` (black) used by the CLI itself.

## Run

Just open `index.html` in any modern browser, or serve the directory
locally:

```sh
python3 -m http.server -d clawd 8000
# then open http://localhost:8000/
```

## What's animating

- bouncing + slight tilt + breathing
- blinking eyes that look around
- rotating, pulsing `✻` sparkle on the antenna
- orbiting dust + drifting twinkling stars in the background
- soft contact shadow that tightens when Clawd lands
