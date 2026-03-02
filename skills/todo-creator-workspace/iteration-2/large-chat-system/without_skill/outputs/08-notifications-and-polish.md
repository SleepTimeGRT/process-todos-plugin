# Notifications and Polish

Add browser push notifications for messages received while the user is away from the chat view, and apply final UX polish to the chat system.

- [ ] Request `Notification` permission on first use of the chat feature and store the result in `localStorage`
- [ ] In `use-chat-actions.ts`, when an `message_received` event arrives for a room that is not currently active (user is on a different page or has a different room open), call `new Notification(senderName, { body: messagePreview, icon: senderAvatar })`
- [ ] Update the browser tab title and favicon badge with the total unread count using `document.title`; reset when the user focuses the chat
- [ ] Add optimistic updates to `MessageInput`: append the message to the local store immediately on send, then reconcile with the server-assigned `id` when the WebSocket broadcast echoes back; show a spinner icon on the bubble until confirmed
- [ ] Handle send failures: if no `message_received` echo arrives within 5 seconds of sending, mark the optimistic message as failed with a retry button
- [ ] Add emoji picker support to `MessageInput` using a lightweight library such as `emoji-mart`
- [ ] Implement message reactions: add a `Reaction` model to Prisma (`messageId`, `userId`, `emoji`), a `POST /api/chat/messages/[messageId]/reactions` endpoint, and display reaction counts below `MessageBubble`
- [ ] Add typing indicators: broadcast `{ type: 'typing', roomId }` on keydown (debounced 500 ms), show "<name> is typing..." in `ChatHeader` for 3 seconds, and clear on message send
- [ ] Write integration tests for the WebSocket `send_message` and `mark_read` flows using `vitest` and a test WebSocket client
- [ ] Document the WebSocket event protocol in a `docs/chat-websocket-protocol.md` file listing all event types, their payloads, and expected server responses
