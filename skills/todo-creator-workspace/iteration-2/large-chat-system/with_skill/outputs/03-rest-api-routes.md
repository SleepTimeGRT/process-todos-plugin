# Implement REST API Routes for Chat Conversations and History

The WebSocket layer handles real-time events, but REST endpoints are needed for operations that are not time-sensitive: fetching conversation lists on page load, paginating message history, creating new conversations, and managing group membership. All routes live under `src/app/api/chat/` using Next.js App Router Route Handlers. Architectural assumption: authentication uses `next-auth` `getServerSession`; all routes return 401 if the session is absent. Cursor-based pagination (using `messageId` as the cursor) is used for message history instead of offset pagination to remain stable under concurrent inserts.

- [ ] Create `src/app/api/chat/conversations/route.ts`:
  - `GET` — return the authenticated user's conversations, ordered by the `createdAt` of the latest message, each including: `id`, `type`, `name`, `members` (id + name + avatarUrl), `lastMessage` (content + sender name + createdAt), `unreadCount` (messages after the user's `lastReadMessageId`)
  - `POST` — create a new conversation; request body: `{ type: 'DIRECT' | 'GROUP', memberIds: string[], name?: string }`; validate that DIRECT conversations have exactly 2 total members (requester + 1), GROUP has 2+; return the created `ConversationWithMembers`
- [ ] Create `src/app/api/chat/conversations/[conversationId]/route.ts`:
  - `GET` — return full conversation details including all members with their `lastReadMessageId`
  - `DELETE` — for GROUP conversations only, allow the requester to leave (removes their `ConversationMember` row); return 403 if DIRECT
- [ ] Create `src/app/api/chat/conversations/[conversationId]/messages/route.ts`:
  - `GET` — paginated message history; query params: `cursor` (messageId, optional), `limit` (default 50, max 100); return `{ messages: MessageWithSender[], nextCursor: string | null }`; exclude soft-deleted message content (replace with `null`, keep the message shell for read-receipt continuity)
- [ ] Create `src/app/api/chat/conversations/[conversationId]/members/route.ts` (GROUP only):
  - `POST` — add a member; body: `{ userId: string }`; return 400 if already a member
  - `DELETE` — remove a member; body: `{ userId: string }`; return 403 if requester is not a member
- [ ] Define Zod validation schemas in `src/lib/chat/api-schemas.ts` for all request bodies and query params; use them in route handlers via a shared `parseBody` / `parseQuery` utility
- [ ] Write tests in `src/__tests__/chat/api-routes.test.ts` using `next-test-api-route-handler` or MSW:
  - `POST /api/chat/conversations` with `type: DIRECT` and 1 `memberId` creates a conversation and returns 201
  - `POST /api/chat/conversations` with `type: DIRECT` and 2 `memberIds` returns 400
  - `GET /api/chat/conversations/[id]/messages` with a `cursor` returns only messages older than the cursor, ordered descending
  - `GET /api/chat/conversations/[id]/messages` soft-deleted messages appear with `content: null`
  - Unauthenticated requests to all routes return 401
  - Non-member `GET` on a conversation returns 403
