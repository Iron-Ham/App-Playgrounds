# ChatBackend

Swift/Vapor backend that powers a local macOS/iOS chat playground. It exposes a lightweight REST API for browsing chat rooms, reading message history, and posting new messages.

## Prerequisites

- Xcode 16 or Swift 6.2 toolchain (macOS 26+)
- SQLite (bundled with macOS)

## Quick start

```bash
swift run ChatBackend
```

The server listens on <http://localhost:8080>. Migrations run automatically on startup and seed two sample rooms (`General`, `Developers`) with a few messages to get you started.

To run the test suite:

```bash
swift test
```

## API overview

| Method | Path | Description |
| ------ | ---- | ----------- |
| `GET` | `/` | Health check – returns a simple status string. |
| `GET` | `/rooms` | Lists chat rooms ordered by creation date (newest first). |
| `POST` | `/rooms` | Creates a new chat room. Body: `{ "name": String, "topic": String? }`. |
| `GET` | `/rooms/{roomID}` | Fetches a single room. Include `?includeMessages=true` to inline the latest 100 messages. |
| `GET` | `/rooms/{roomID}/messages` | Returns messages for the room (newest last). Optional query `limit` (1-200, default 50). |
| `POST` | `/rooms/{roomID}/messages` | Sends a new message. Body: `{ "sender": String, "body": String }`. |

### Sample requests

List rooms:

```bash
curl http://localhost:8080/rooms | jq
```

Create a room:

```bash
curl -X POST http://localhost:8080/rooms \
	-H "Content-Type: application/json" \
	-d '{"name":"Design","topic":"UI feedback"}' | jq
```

Post a message:

```bash
curl -X POST http://localhost:8080/rooms/<room-id>/messages \
	-H "Content-Type: application/json" \
	-d '{"sender":"Me","body":"Hello, team!"}' | jq
```

Fetch recent history for a room:

```bash
curl "http://localhost:8080/rooms/<room-id>/messages?limit=25" | jq
```

## Notes

- SQLite database lives at `db.sqlite` in the project root. Delete the file to reset all data.
- Example data is created once per migration run via `SeedChatData`.
- Extend the API by adding new route collections under `Sources/ChatBackend/Controllers`.

## Shared DTO module

- The pure Codable DTOs used by the API reside in the `ChatSharedDTOs` library product within this package. Add the package as a dependency in other apps (such as the SwiftUI client) and `import ChatSharedDTOs` to reuse the payload types without bringing along Vapor.

### Further reading

- [Vapor Documentation](https://docs.vapor.codes)
- [Fluent ORM Documentation](https://docs.vapor.codes/fluent/overview/)
