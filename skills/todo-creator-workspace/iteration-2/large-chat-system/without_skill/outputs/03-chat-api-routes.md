# Chat REST API Routes

Create Next.js API route handlers for chat room and message management. These REST endpoints handle operations that do not need to be real-time (room creation, history loading, member management) and serve as the authoritative source of truth backed by Prisma.

- [ ] Create `app/api/chat/rooms/route.ts`: `GET` returns the authenticated user's room list with last message preview and unread count; `POST` creates a new room (accepts `type`, `name`, `memberIds[]`)
- [ ] Create `app/api/chat/rooms/[roomId]/route.ts`: `GET` returns room details and member list; `PATCH` updates room name (group only, admin only); `DELETE` soft-deletes or archives the room
- [ ] Create `app/api/chat/rooms/[roomId]/messages/route.ts`: `GET` returns paginated messages (cursor-based, query params `cursor` and `limit`); `POST` is a fallback HTTP message send for clients without WebSocket support
- [ ] Create `app/api/chat/rooms/[roomId]/members/route.ts`: `POST` adds a member to a group room; `DELETE` removes a member
- [ ] Create `app/api/chat/rooms/[roomId]/read/route.ts`: `POST` marks all messages in the room as read for the authenticated user by updating `ChatRoomMember.lastReadAt` and upserting `MessageReadReceipt` rows
- [ ] Add an auth guard helper `lib/chat/auth-guard.ts` that reads the session and throws a 401 response if unauthenticated; reuse it in all chat route handlers
- [ ] Add input validation with `zod` for all POST/PATCH request bodies
- [ ] Enforce that `DIRECT` rooms have exactly 2 members and prevent duplicate direct rooms between the same pair of users
