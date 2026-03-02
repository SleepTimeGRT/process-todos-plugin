# Implement Chat REST API Endpoints

REST API for operations that don't need real-time delivery: fetching history, creating conversations, managing group participants. WebSocket handles live events; REST handles initial load and management actions. Depends on DB schema from todo #1.

Pagination uses cursor-based approach (by message ID / created_at) rather than offset — this prevents the "shifting results" problem when new messages arrive during pagination.

- [ ] Create `src/routes/chat.ts` (or equivalent router file for your framework) and mount at `/api/chat`
- [ ] `GET /api/chat/conversations` — list authenticated user's conversations, ordered by `updated_at DESC`:
  - Join with `conversation_participants` (filter by current userId), `messages` (latest message subquery), `users` (participant info)
  - Include `unread_count` per conversation: count of messages where `created_at > last_read_at` for current user
  - Response: `{ conversations: Conversation[] }` with `lastMessage` and `unreadCount` populated
- [ ] `POST /api/chat/conversations` — create a new conversation:
  - Body: `{ type: 'direct' | 'group', participantIds: string[], name?: string }`
  - For `direct`: check if a direct conversation already exists between these two users — if so, return existing (idempotent). Block if `participantIds.length !== 1`.
  - For `group`: require `name`, require `participantIds.length >= 2`
  - Always add the creator as a participant with `is_admin: true`
  - Insert system message: `"[Name] created this group"` for group chats
  - Response: `{ conversation: Conversation }` with participants populated
- [ ] `GET /api/chat/conversations/:id/messages` — paginated message history:
  - Query params: `cursor?: string` (message id), `limit?: number` (default 50, max 100)
  - If cursor provided: `WHERE created_at < (SELECT created_at FROM messages WHERE id = $cursor)`
  - Join with sender user info
  - Derive `readBy` for each message: list of participant userIds whose `last_read_at >= message.created_at`
  - Response: `{ messages: Message[], nextCursor: string | null }`
- [ ] `POST /api/chat/conversations/:id/participants` — add users to group chat:
  - Require caller to be `is_admin` of the conversation
  - Body: `{ userIds: string[] }`
  - Insert into `conversation_participants`, emit WS event `participant:joined` for each new member
  - Insert system message: `"[Admin] added [User] to the group"`
- [ ] `DELETE /api/chat/conversations/:id/participants/:userId` — leave or remove from group:
  - User can remove themselves; admin can remove others
  - Delete from `conversation_participants`
  - Emit WS event `participant:left`
  - If last participant leaves, mark conversation as archived (add `archived_at` column)
- [ ] `GET /api/users/search?q=` — search users by name/email to start a new chat:
  - Exclude current user from results
  - Return: `{ users: Array<{ id, name, avatarUrl, isOnline }> }` (isOnline from ConnectionManager)
  - Limit to 20 results
- [ ] Write tests in `src/routes/__tests__/chat.test.ts`: (a) POST /conversations with type=direct is idempotent — calling twice returns same conversation, (b) GET /conversations/:id/messages cursor pagination returns correct page, (c) non-participant cannot fetch messages (403), (d) non-admin cannot add participants to group (403)