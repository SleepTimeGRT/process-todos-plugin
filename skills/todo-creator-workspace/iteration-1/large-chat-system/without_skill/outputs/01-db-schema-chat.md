# Add Prisma schema for chat system

The real-time chat feature requires a data model that supports 1:1 and group conversations, per-message read receipts, and integration with the existing User model. This schema is the foundation everything else builds on, so it must be done first.

- [ ] In `prisma/schema.prisma`, add a `Conversation` model with fields: `id` (cuid), `type` (enum: `DIRECT` | `GROUP`), `name` (String?, used for group chat display name), `createdAt`, `updatedAt`
- [ ] Add a `ConversationMember` join model with fields: `id`, `conversationId` (relation to `Conversation`), `userId` (relation to existing `User`), `joinedAt`, `lastReadAt` (DateTime?, tracks read position per member per conversation). Add a unique constraint on `[conversationId, userId]`.
- [ ] Add a `Message` model with fields: `id` (cuid), `conversationId` (relation to `Conversation`), `senderId` (relation to `User`), `content` (String), `createdAt`, `updatedAt`, `deletedAt` (DateTime?, for soft delete)
- [ ] Add a `MessageReadReceipt` model with fields: `id`, `messageId` (relation to `Message`), `userId` (relation to `User`), `readAt` (DateTime). Add a unique constraint on `[messageId, userId]`.
- [ ] Run `npx prisma migrate dev --name add-chat-system` to generate and apply the migration
- [ ] Run `npx prisma generate` to regenerate the Prisma client
- [ ] Verify the migration file exists under `prisma/migrations/` and contains the expected SQL (CREATE TABLE for Conversation, ConversationMember, Message, MessageReadReceipt)
