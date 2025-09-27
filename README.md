# App Playgrounds

A collection of Swift demo applications and experiments showcasing different frameworks, APIs, and development patterns.

## Projects Overview

### 🗨️ Chat
A real-time chat application built with Swift/Vapor backend and SwiftUI frontend.

- **Backend (`Chat/ChatBackend`)**: REST API server using Vapor framework with SQLite database
- **Frontend (`Chat/ChatFrontend`)**: Native SwiftUI macOS/iOS chat client

**Features:**
- Multiple chat rooms
- Real-time messaging
- Message history
- Shared DTOs between client and server

### 🎮 TicTacToe(N)
An extensible N×N Tic-Tac-Toe game built with SwiftUI.

**Features:**
- Configurable board size (3×3, 4×4, etc.)
- Move history and undo functionality
- Win detection for horizontal, vertical, and diagonal patterns
- Clean SwiftUI interface with @Observable game state

### 🌌 SWAPI
Star Wars API integration examples with multiple UI framework implementations.

**Components:**
- **API Library**: Core networking layer for SWAPI endpoints
- **SwiftUI App**: Modern declarative UI implementation
- **UIKit App**: Traditional imperative UI implementation

**Features:**
- Film data fetching from SWAPI
- Error handling and loading states
- Structured response models

### 🎨 Crayon
AI-powered color generation using Apple's Foundation Models.

**Features:**
- Natural language color descriptions (e.g., "Forest Green", "Electric Yellow")
- On-device AI model for color generation
- SwiftUI and UIKit color support
- RGBA component extraction

## Requirements

- **Xcode 26+** or Swift 6.2 toolchain
- **macOS 26+** (for Foundation Models support in Crayon)
- **iOS 17+** / **macOS 14+** (for SwiftUI apps)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Hesham Salman** - [@Iron-Ham](https://github.com/Iron-Ham)

---

*These playgrounds demonstrate various Swift development patterns and serve as learning resources for iOS/macOS app development, server-side Swift, and modern AI integration.*