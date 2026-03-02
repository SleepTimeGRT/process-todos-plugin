# Read Receipts Implementation

Implement the end-to-end read receipt feature. This involves tracking when users read messages, broadcasting that information in real time, and reflecting it accurately in the UI with appropriate visual indicators.

- [ ] On `MessageList` mount and when the component scrolls to the bottom, call `POST /api/chat/rooms/[roomId]/read` to mark all messages as read; also send `{ type: 'mark_read', roomId }` over WebSocket for immediate broadcast
- [ ] In the WebSocket server `mark_read` handler, upsert `MessageReadReceipt` for each unread message in the room for that user, then broadcast `{ type: 'read_update', roomId, userId, readUpTo: <latest messageId> }` to all room members
- [ ] In the Zustand store `updateReadReceipt` action, track which `userId` has read up to which `messageId` per room; store this as `readStatus: Record<roomId, Record<userId, string>>` where the value is the latest read `messageId`
- [ ] In `MessageBubble`, compute read status by comparing the message's `id` against each member's `readStatus` entry: if all non-sender members have a `readStatus` entry with an ID >= this message's ID, show double-check; otherwise show single-check
- [ ] For group rooms with many members, show a count instead of per-user avatars: e.g., "Read by 3" with a tooltip listing names on hover
- [ ] For 1:1 direct rooms, show the other participant's avatar next to the last message they have read
- [ ] Handle the edge case where a user is offline: their read receipt is recorded via REST when they next open the room, and the real-time broadcast is skipped for offline clients
- [ ] Add a `lastReadAt` field display in `RoomListItem` to indicate when the other party last read messages in a direct room
