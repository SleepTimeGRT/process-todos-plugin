# Implement Chat REST API Routes

This todo adds the HTTP API layer for the chat system. These routes handle conversation management and message persistence. After a message is saved to the database, the route calls `broadcastToUsers` (from the WS handler) to push the new message event to connected participants in real time. This todo can be worked on in parallel with todo 02 (WebSocket server), but must come after todo 01 (DB schema).

- [ ] Create `src/app/api/conversations/route.ts`:
  - `GET /api/conversations` — returns all conversations the authenticated user is a participant of, ordered by most recent message. Include for each: `id`, `name`, `isGroup`, participant list (id, name, avatar), last message preview, and unread count (computed as number of messages with `createdAt > participant.lastReadAt`). Paginate with `cursor`-based pagination.
  - `POST /api/conversations` — creates a new conversation. Body: `{ participantIds: string[], name?: string, isGroup: boolean }`. For 1:1 chats, check if a conversation already exists between the two users and return it instead of creating a duplicate. Returns the full conversation object.

- [ ] Create `src/app/api/conversations/[id]/route.ts`:
  - `GET /api/conversations/[id]` — returns full conversation details including participant list. Returns 403 if the authenticated user is not a participant.
  - `PATCH /api/conversations/[id]` — update conversation name (group chats only). Only participants can rename.
  - `DELETE /api/conversations/[id]` — soft-leave: removes the authenticated user from `ConversationParticipant`. If this was the last participant, mark the conversation as deleted (or hard-delete, your choice).

- [ ] Create `src/app/api/conversations/[id]/messages/route.ts`:
  - `GET /api/conversations/[id]/messages` — returns paginated messages for the conversation (cursor-based, ordered by `createdAt DESC`). Include sender info (`id`, `name`, `image`). Returns 403 if caller is not a participant.
  - `POST /api/conversations/[id]/messages` — creates a new message. Body: `{ content: string }`. After persisting:
    1. Update `ConversationParticipant.lastReadAt` for the sender (they've just read their own message).
    2. Call `broadcastToUsers(participantIds, { type: 'NEW_MESSAGE', message })` to push the event to all connected participants.
    Returns the created message with sender info.

- [ ] Create `src/app/api/conversations/[id]/participants/route.ts`:
  - `POST /api/conversations/[id]/participants` — add a user to a group conversation. Body: `{ userId: string }`. Only works for `isGroup: true` conversations.
  - `DELETE /api/conversations/[id]/participants/[userId]` — remove a participant from a group conversation (self-removal or admin removal).

- [ ] Create a shared utility `src/lib/chat/conversation-queries.ts` with typed Prisma query helpers:
  - `getConversationWithAccess(conversationId, userId)` — fetches a conversation and throws a typed error if the user is not a participant. Used by multiple routes to avoid duplicating auth logic.
  - `getUnreadCount(conversationId, userId)` — returns message count since `lastReadAt`.

- [ ] Add input validation using `zod` for all POST/PATCH request bodies. Create schemas in `src/lib/chat/schemas.ts`.

- [ ] Write route handler unit tests in `src/app/api/conversations/__tests__/` using Next.js route handler test utilities (mock `prisma` client and the `broadcastToUsers` function).
