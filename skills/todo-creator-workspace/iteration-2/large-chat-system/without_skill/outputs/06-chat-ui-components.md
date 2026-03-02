# Chat UI Components

Build the React component tree for the chat interface. Components should be composable, client-side rendered where interactivity is needed, and consume state from the Zustand store.

- [ ] Create `components/chat/ChatSidebar.tsx`: list all rooms the user belongs to, showing room name (or other participant's name for direct rooms), last message preview, timestamp, and an unread badge from `unreadCounts`
- [ ] Create `components/chat/RoomListItem.tsx`: individual row in the sidebar; highlight the active room; clicking navigates to `/chat/[roomId]` using Next.js `useRouter`
- [ ] Create `components/chat/MessageList.tsx`: virtualized scrollable list of messages using `@tanstack/react-virtual`; fetch older messages on scroll-to-top via the paginated REST API; mark room as read when the component gains focus or scrolls to bottom
- [ ] Create `components/chat/MessageBubble.tsx`: renders a single message with sender avatar, content, timestamp, and a read indicator icon (single check = sent, double check = all members have read)
- [ ] Create `components/chat/MessageInput.tsx`: textarea with send button; pressing Enter (without Shift) submits; calls `send({ type: 'send_message', roomId, content })` via the socket hook; shows character count limit
- [ ] Create `components/chat/ChatHeader.tsx`: displays room name, participant count for group rooms, and an online indicator based on socket `status`
- [ ] Create `components/chat/NewChatModal.tsx`: a modal to start a new direct message (user search) or create a group room (multi-select users + room name input); calls `POST /api/chat/rooms` on submit
- [ ] Create `app/chat/[roomId]/page.tsx` as a client component that composes `ChatHeader`, `MessageList`, and `MessageInput`; initializes the socket hook and passes `roomIds` from the store
- [ ] Create `app/chat/layout.tsx` that renders `ChatSidebar` alongside the main content area as a split-pane layout
- [ ] Add loading skeletons for the sidebar and message list using the project's existing skeleton component or Tailwind pulse animations
