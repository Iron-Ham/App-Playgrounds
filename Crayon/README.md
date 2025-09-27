# Crayon

Utility to generate `SwiftUI.Color` values from descriptive names using Apple's Foundation Models guided generation (`Generable`). This version assumes the framework is always available (no heuristic fallback).

## Features

- Guided generation via `FoundationModels` (`@Generable` + `@Guide`).
- Simple testable RGBA container (`ColorGenerator.RGBA`).

## Example

```swift
import Crayon
import SwiftUI

let color = try await ColorGenerator.color(named: "Electric Yellow")
```

## Using Foundation Models

`ColorGenerator`:

1. Creates a `LanguageModelSession(model: .default)`.
2. Prompts it to generate a `GeneratedColor` (`@Generable`) with RGB components constrained to 0–1.
3. Converts the result to `SwiftUI.Color`.

If generation fails (throws), you decide how to handle it (e.g. fallback to a static color at the call site).

## Testing

Tests avoid invoking the model (which would be non-deterministic) and instead validate local utility behavior like RGBA clamping.

Run:

```
swift test
```

## Roadmap / Ideas

- Inject a custom `LanguageModelSession` for deterministic testing.
- Add alpha channel guidance.
- Provide an HSL-based generation option.
- Add validation utilities for naming conventions.

## License

MIT (add your preferred license here).
