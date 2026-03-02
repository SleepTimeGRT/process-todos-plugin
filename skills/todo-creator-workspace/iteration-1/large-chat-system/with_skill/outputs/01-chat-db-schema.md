# Add Chat System Database Schema

This is the foundational todo for the real-time chat system. All other chat todos depend on this schema being in place first. We use a Conversation/Participant model that handles both 1:1 and group chats uniformly — a 1:1 chat is just a Conversation with exactly two participants and `isGroup: false`.

- [ ] Add the following models to `prisma/schema.prisma`:
  - `Conversation` with fields: `id` (cuid), `name` (String, optional — used for group chats), `isGroup` (Boolean, default false), `createdAt`, `updatedAt`
  - `ConversationParticipant` with fields: `id`, `conversationId` (FK to Conversation), `userId` (FK to User), `joinedAt`, `lastReadAt` (DateTime, nullable — used to compute unread counts and render read receipts). Add a unique constraint on `[conversationId, userId]`.
  - `Message` with fields: `id` (cuid), `conversationId` (FK to Conversation), `senderId` (FK to User), `content` (String), `createdAt`, `updatedAt`, `deletedAt` (DateTime, nullable — soft delete)
- [ ] Add the inverse relations on the existing `User` model: `conversations ConversationParticipant[]` and `messages Message[]`
- [ ] Add `@@index([conversationId, createdAt])` on `Message` for efficient paginated message loading
- [ ] Add `@@index([userId])` on `ConversationParticipant` for efficient "my conversations" queries
- [ ] Run `npx prisma migrate dev --name add-chat-schema` to generate and apply the migration
- [ ] Run `npx prisma generate` to regenerate the Prisma client
- [ ] Write a seed snippet (or update `prisma/seed.ts` if it exists) that creates one sample 1:1 conversation and one sample group conversation between existing seed users, so the feature can be manually tested immediately after setup
