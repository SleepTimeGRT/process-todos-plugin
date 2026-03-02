# Implement WebSocket Server with Connection and Room Management

This layer is the real-time backbone of the chat system. It manages persistent WebSocket connections, routes events between users, and handles presence (online/offline). It depends on the types from todo #1.

Design decisions documented here: (1) Connections are stored in a Map keyed by userId — one user can have multiple tabs, so we store `Map<userId, Set<WebSocket>>`. (2) Rooms mirror conversation IDs — when a message arrives for conversationId X, we look up all participants of X and push to their active connections. (3) Typing indicators are NOT persisted to DB — they exist only in memory with a 3-second auto-expire timer.

- [ ] Install dependencies: `npm install ws` and `npm install -D @types/ws`
- [ ] Create `src/lib/chat/connection-manager.ts` — a singleton `ConnectionManager` class:
  - `private connections = new Map<string, Set<WebSocket>>()` (userId → active sockets)
  - `add(userId: string, ws: WebSocket): void` — registers connection, sets up cleanup on `ws.on('close', ...)`
  - `remove(userId: string, ws: WebSocket): void` — removes socket, if Set is now empty emits `user:offline` to relevant conversations
  - `send(userId: string, event: WsServerEvent): void` — sends to all sockets for that user
  - `broadcast(userIds: string[], event: WsServerEvent): void` — sends to multiple users (deduplicates)
  - `isOnline(userId: string): boolean`
- [ ] Create `src/lib/chat/ws-server.ts` — sets up the WebSocket server:
  - Attach to existing HTTP server: `new WebSocketServer({ server: httpServer })`
  - On connection: authenticate via JWT from query param `?token=...` (extract userId), call `connectionManager.add(userId, ws)`, broadcast `user:online` to contacts
  - On message: parse JSON, validate shape against `WsClientEvent`, route to appropriate handler
  - Wrap all handlers in try/catch; on error send `{ type: 'error', payload: { message: string } }` back to client
- [ ] Create `src/lib/chat/ws-handlers.ts` — one exported async function per client event type:
  - `handleSendMessage(userId, payload)`: validate user is participant of conversation → insert message into DB → update `conversations.updated_at` → call `broadcastToConversation(conversationId, { type: 'message:new', payload: message })`
  - `handleDeleteMessage(userId, payload)`: verify sender === userId → soft-delete (set deleted_at) → broadcast `message:deleted`
  - `handleMarkRead(userId, payload)`: UPDATE conversation_participants SET last_read_at = NOW() → broadcast `read:updated` to conversation participants
  - `handleTypingStart/Stop(userId, payload)`: maintain `Map<conversationId, Map<userId, NodeJS.Timeout>>` — on start, set 3s timeout that auto-fires stop; broadcast typing event to other participants only (not sender)
- [ ] Create helper `broadcastToConversation(conversationId: string, event: WsServerEvent)` in `ws-server.ts`: queries `conversation_participants` for all userIds in that conversation, calls `connectionManager.broadcast(userIds, event)`
- [ ] Write tests in `src/lib/chat/__tests__/ws-handlers.test.ts` using mock WebSocket and mock DB: (a) handleSendMessage rejects if user is not a participant, (b) handleMarkRead updates last_read_at and broadcasts read:updated, (c) typing indicator auto-stops after 3 seconds, (d) deleted message sets deleted_at and does not expose content in broadcast