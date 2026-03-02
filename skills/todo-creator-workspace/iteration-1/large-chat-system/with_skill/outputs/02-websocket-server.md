# Set Up WebSocket Server for Real-time Chat

This todo establishes the real-time transport layer for the chat system. We use WebSocket (via the `ws` library) over SSE because chat is bidirectional — clients send messages and receive them — and WebSocket is a better fit than SSE's one-way push model. Next.js is extended with a custom server (`server.ts`) that runs the HTTP server and WS server on the same port. Authentication is handled at the WS handshake by reading the session cookie (using the existing auth mechanism).

- [ ] Install dependencies: `npm install ws` and `npm install --save-dev @types/ws`
- [ ] Create `server.ts` at the project root. This file creates an `http.Server` wrapping the Next.js request handler and attaches a `ws.WebSocketServer` to it on the same port. Export nothing — this is the entry point. Example shape:
  ```ts
  import { createServer } from 'http';
  import next from 'next';
  import { WebSocketServer } from 'ws';
  import { setupChatWebSocket } from './src/lib/chat/ws-handler';

  const app = next({ dev: process.env.NODE_ENV !== 'production' });
  const handle = app.getRequestHandler();
  app.prepare().then(() => {
    const server = createServer((req, res) => handle(req, res));
    const wss = new WebSocketServer({ server });
    setupChatWebSocket(wss);
    server.listen(3000);
  });
  ```
- [ ] Update `package.json` scripts: change `"dev"` to `"tsx server.ts"` (install `tsx` if not present: `npm install --save-dev tsx`), and add `"start": "NODE_ENV=production tsx server.ts"`
- [ ] Create `src/lib/chat/ws-handler.ts`. This module exports `setupChatWebSocket(wss: WebSocketServer)`. Responsibilities:
  - On new WS connection: authenticate the user by parsing cookies from the upgrade request headers using the existing auth session utility. If auth fails, close the connection with code 4001.
  - Maintain an in-memory map `Map<userId, Set<WebSocket>>` to track which sockets belong to which user (a user may have multiple tabs open).
  - Export a function `broadcastToUsers(userIds: string[], payload: object)` that sends a JSON payload to all active sockets for the given user IDs. This function will be called by the message-sending API route after persisting a message.
- [ ] Define WebSocket message types in `src/lib/chat/ws-types.ts`:
  ```ts
  export type WsServerEvent =
    | { type: 'NEW_MESSAGE'; message: MessagePayload }
    | { type: 'READ_RECEIPT'; conversationId: string; userId: string; lastReadAt: string }
    | { type: 'USER_TYPING'; conversationId: string; userId: string; isTyping: boolean }
    | { type: 'ERROR'; code: string; message: string };

  export type WsClientEvent =
    | { type: 'TYPING'; conversationId: string; isTyping: boolean }
    | { type: 'MARK_READ'; conversationId: string };
  ```
  The `MessagePayload` type mirrors the Prisma `Message` shape with sender info included.
- [ ] In `ws-handler.ts`, handle incoming client messages (`WsClientEvent`):
  - `TYPING`: broadcast `USER_TYPING` event to all participants of that conversation (except the sender) using `broadcastToUsers`
  - `MARK_READ`: update `ConversationParticipant.lastReadAt` for this user in the DB, then broadcast `READ_RECEIPT` to all participants
- [ ] Write a simple integration test in `src/lib/chat/__tests__/ws-handler.test.ts` using `ws` in test mode (create a real WS server on a random port, connect two mock clients, verify event delivery)
