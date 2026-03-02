# Define Chat System Database Schema with Prisma

The chat system's correctness and query performance depend entirely on the data model. This todo establishes the Prisma schema for all chat entities before any business logic is written. Architectural assumptions: a `Conversation` model serves both 1:1 and group chats (distinguished by a `type` enum and an optional `name`), read receipts are tracked per-member per-conversation (storing the last-read message ID rather than a boolean per message, which scales better), and soft-delete is used for messages to preserve read-receipt integrity.

- [ ] Add the following models to `prisma/schema.prisma`:
  - `Conversation` — fields: `id`, `type` (enum: `DIRECT` | `GROUP`), `name` (nullable, for group chats), `createdAt`, `updatedAt`
  - `ConversationMember` — join table: `conversationId`, `userId`, `joinedAt`, `lastReadMessageId` (nullable FK to `Message`)
  - `Message` — fields: `id`, `conversationId`, `senderId`, `content`, `createdAt`, `deletedAt` (nullable for soft-delete)
  - Add indexes: `Message(conversationId, createdAt)` for paginated history queries, `ConversationMember(userId, conversationId)` for membership lookups
- [ ] Define the `ConversationType` enum in `prisma/schema.prisma`
- [ ] Add relations:
  - `User` has many `ConversationMember` and many `Message`
  - `Conversation` has many `ConversationMember` and many `Message`
  - `ConversationMember.lastReadMessage` is an optional relation to `Message`
- [ ] Run `npx prisma migrate dev --name add_chat_system` to generate and apply the migration
- [ ] Create seed data in `prisma/seed/chat.ts` with at least: 2 direct conversations and 1 group conversation with 3 members, plus 10 messages each, with varying `lastReadMessageId` values to seed read-receipt state
- [ ] Define shared TypeScript types in `src/types/chat.ts`:
  - `ConversationType` (re-export from Prisma client)
  - `ConversationWithMembers` (Prisma result type with `members` and `_count.messages`)
  - `MessageWithSender` (Prisma result type with `sender: { id, name, avatarUrl }`)
  - `ReadReceiptInfo` — `{ userId: string; userName: string; lastReadMessageId: string }`
- [ ] Write tests in `src/__tests__/db/chat-schema.test.ts` covering:
  - Creating a DIRECT conversation enforces exactly 2 members (via a Prisma middleware or service-layer check — document which approach is chosen)
  - Updating `lastReadMessageId` on `ConversationMember` does not cascade-delete anything
  - Soft-deleted messages (`deletedAt != null`) are excluded from default query helpers
  - Index presence verified via `prisma.$queryRaw` explain plan (optional, document as a future concern if skipped)
