# WebSocket Server Setup

Implement the real-time transport layer using WebSockets (via the `ws` library with a custom Next.js server). WebSockets are chosen over SSE because chat requires full-duplex communication — both sending and receiving messages — and SSE is one-directional. A custom Next.js server (`server.ts`) is needed to attach the WebSocket server to the same HTTP port.

- [ ] Install dependencies: `npm install ws` and `npm install --save-dev @types/ws`
- [ ] Create `server.ts` at project root to bootstrap a custom Next.js HTTP server with `next` and attach a `ws.WebSocketServer` to it
- [ ] Define a `SocketClient` type that extends `ws.WebSocket` with fields: `userId: string`, `rooms: Set<string>`
- [ ] Implement a `clients: Map<string, SocketClient>` registry keyed by `userId` for targeted messaging
- [ ] On WebSocket `connection`, authenticate the user from the upgrade request (read session cookie / JWT header); close the socket with code 4001 if unauthenticated
- [ ] On successful connection, register the client in the map, restore their room memberships from the database, and send a `connected` confirmation event
- [ ] Handle incoming message types: `join_room`, `leave_room`, `send_message`, `mark_read`, `ping`
- [ ] Implement `join_room` handler: verify the requesting user is a member of the room in the database, then add the room to `client.rooms`
- [ ] Implement `send_message` handler: persist the message via Prisma, then broadcast it to all connected clients whose `rooms` set includes the target room
- [ ] Implement `mark_read` handler: upsert `MessageReadReceipt` rows and broadcast a `read_update` event to the room
- [ ] Implement `ping` / `pong` heartbeat to detect stale connections; remove dead clients from the registry on `close`
- [ ] Update `package.json` `dev` and `start` scripts to run `ts-node server.ts` instead of `next dev` / `next start`
