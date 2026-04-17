# Industrial Telemetry Visual System

## Palette

- Background: `#FFE258`
- Primary UI dark: `#332C0C`
- LED accent: `#D8BF4D`

## Rules

- No gradients.
- No transparency-heavy layering.
- No default modern mobile chrome.
- Panels must feel bolted in, bordered, and operational.
- Icons should be ASCII glyphs or monospaced glyph treatments.

## Typography

- `Press Start 2P`: headers, navigation labels
- `Digital-7`: clocks, counters, timers
- `Courier` or `Menlo`: logs, file names, metadata
- `Arial Black`: branding or industrial title treatment
- `SF Pro Text`: alerts and system overlays

## Layout

- Fixed top header and fixed tab rail/footer.
- State-switched panels instead of deep push navigation.
- Panels should use hatch marks, plus-sign corners, and hard border treatments.
- LED indicators communicate activity or focus.
- The shell must detect portrait versus landscape orientation and reflow its panel layout, tab arrangement, and footer/status placement to suit the current orientation.
