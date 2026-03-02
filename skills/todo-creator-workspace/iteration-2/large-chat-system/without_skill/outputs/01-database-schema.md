# Database Schema for Chat System

Set up the Prisma schema to support 1:1 direct messages, group chat rooms, messages, and read receipts. This forms the data foundation that all other chat features depend on.

- [ ] Add `ChatRoom` model with fields: `id`, `type` (enum: `DIRECT`, `GROUP`), `name` (nullable, for group rooms), `createdAt`, `updatedAt`
- [ ] Add `ChatRoomMember` join model with fields: `id`, `roomId`, `userId`, `joinedAt`, `lastReadAt` (for read receipts)
- [ ] Add `Message` model with fields: `id`, `roomId`, `senderId`, `content`, `createdAt`, `updatedAt`, `deletedAt` (soft delete)
- [ ] Add `MessageReadReceipt` model with fields: `id`, `messageId`, `userId`, `readAt` to track per-message read status
- [ ] Define relations: `ChatRoom` has many `ChatRoomMember` and many `Message`; `Message` has many `MessageReadReceipt`
- [ ] Add appropriate indexes: `ChatRoomMember(roomId, userId)` unique, `Message(roomId, createdAt)`, `MessageReadReceipt(messageId, userId)` unique
- [ ] Run `prisma migrate dev --name add-chat-system` to apply the schema
- [ ] Run `prisma generate` to update the Prisma client
