# Implement WebSocket Server for Real-Time Chat

WebSocket was chosen over SSE because the chat feature requires true bidirectional communication: clients both send messages and receive them, and read-receipt updates must be pushed to all conversation participants immediately. SSE is unidirectional and would require a separate REST call per send, adding complexity and latency. This todo implements the WebSocket server using `ws` (or `socket.io` if the project already uses it — prefer `socket.io` for its built-in room management and reconnection handling). Architectural assumption: the WebSocket server runs as a Next.js custom server in `server.ts`, not as an API route, because Next.js API routes do not support persistent connections.

- [ ] Install dependencies: `socket.io`, `socket.io-client`; add `@types/ws` if using raw `ws`
- [ ] Create `server.ts` at the project root (Next.js custom server) that:
  - Boots an `http.Server` wrapping the Next.js app handler
  - Attaches a `socket.io` `Server` instance to the HTTP server
  - Exports a `getIO()` singleton so other modules can emit events without passing the instance around
- [ ] Define the WebSocket event protocol in `src/lib/chat/events.ts` as typed constants and payload interfaces:
  - Client → Server: `chat:join` `{ conversationId }`, `chat:leave` `{ conversationId }`, `chat:send` `{ conversationId, content }`, `chat:read` `{ conversationId, messageId }`
  - Server → Client: `chat:message` `{ message: MessageWithSender }`, `chat:read_receipt` `{ conversationId, userId, lastReadMessageId }`, `chat:error` `{ code: ChatErrorCode, message: string }`
  - Define `ChatErrorCode` enum: `UNAUTHORIZED`, `CONVERSATION_NOT_FOUND`, `NOT_A_MEMBER`, `MESSAGE_TOO_LONG`
- [ ] Implement `src/lib/chat/socket-handler.ts` — a function `registerChatHandlers(io: Server, socket: Socket)` that:
  - Authenticates the socket on `connection` using the session cookie (call `getServerSession` from `next-auth`); disconnect with `chat:error { code: UNAUTHORIZED }` if unauthenticated
  - Handles `chat:join`: verify membership via Prisma, then call `socket.join(conversationId)`
  - Handles `chat:send`: validate content length (≤ 2000 chars), persist `Message` via Prisma, then emit `chat:message` to the room
  - Handles `chat:read`: update `ConversationMember.lastReadMessageId`, then emit `chat:read_receipt` to all room members except the sender
  - Handles `chat:leave`: call `socket.leave(conversationId)`
  - All handlers wrap logic in try/catch and emit `chat:error` on failure
- [ ] Register `registerChatHandlers` inside `server.ts` on each `io.on('connection', socket => ...)`
- [ ] Update `package.json` `dev` and `start` scripts to run `ts-node server.ts` instead of `next dev` / `next start`
- [ ] Write tests in `src/__tests__/chat/socket-handler.test.ts` using `socket.io-mock` or an in-process `socket.io` test setup:
  - Unauthenticated socket receives `chat:error { code: UNAUTHORIZED }` and is disconnected
  - `chat:send` from a member persists the message and broadcasts `chat:message` to all room sockets
  - `chat:send` with content > 2000 chars emits `chat:error { code: MESSAGE_TOO_LONG }` and does not persist
  - `chat:read` updates `lastReadMessageId` in DB and broadcasts `chat:read_receipt` to other room members only (not sender)
  - Non-member calling `chat:join` receives `chat:error { code: NOT_A_MEMBER }`
