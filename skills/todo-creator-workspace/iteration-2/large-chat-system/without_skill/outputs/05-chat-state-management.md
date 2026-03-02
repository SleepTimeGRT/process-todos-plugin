# Chat State Management

Implement client-side state management for chat data using Zustand. This store acts as the single source of truth for room lists, message histories, and read receipt state, and is updated by both REST responses and incoming WebSocket events.

- [ ] Install Zustand: `npm install zustand`
- [ ] Create `store/chat-store.ts` and define the store with `create<ChatStore>()(...)` using Zustand's `immer` middleware for ergonomic nested updates
- [ ] Define types: `Room`, `Message`, `Member`, `ReadReceipt` mirroring the Prisma models but as plain client-side objects
- [ ] Add state slices: `rooms: Record<string, Room>`, `messages: Record<string, Message[]>` (keyed by roomId), `unreadCounts: Record<string, number>` (keyed by roomId)
- [ ] Add actions: `setRooms`, `upsertRoom`, `setMessages`, `appendMessage`, `updateReadReceipt`, `decrementUnread`, `resetUnread`
- [ ] Implement `appendMessage(roomId, message)`: push the new message to `messages[roomId]`, update `rooms[roomId].lastMessage`, and increment `unreadCounts[roomId]` only if the sender is not the current user
- [ ] Implement `updateReadReceipt(roomId, userId, messageIds)`: update per-message read state and, if `userId` is the current user, call `resetUnread(roomId)`
- [ ] Create `hooks/use-chat-actions.ts` that consumes `use-chat-socket` and wires incoming `ChatEvent`s to the appropriate Zustand store actions
- [ ] On app load, fetch room list from `GET /api/chat/rooms` and hydrate the store via `setRooms`
