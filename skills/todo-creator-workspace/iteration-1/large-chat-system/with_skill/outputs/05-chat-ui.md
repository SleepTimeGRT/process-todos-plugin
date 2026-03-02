# Build Chat UI Components and Pages

This is the final todo for the real-time chat system. It wires together all the infrastructure built in todos 01–04 into a user-facing chat interface. The UI features a conversation list sidebar, a message thread view, read receipts, typing indicators, and a new conversation dialog (for starting 1:1 or group chats).

- [ ] Create the main chat page at `src/app/chat/page.tsx`. This is a client component (`'use client'`) that initializes `useChatSocket()` (so the WS connection starts when the user visits the chat page) and renders the two-panel layout: `<ConversationList />` on the left, `<ConversationView />` on the right. Apply a responsive layout that collapses to single-column on mobile (show list by default, show conversation when one is selected).

- [ ] Create `src/components/chat/ConversationList.tsx`:
  - Uses `useConversations()` hook to load and display conversations
  - Each item shows: participant avatar(s), conversation name, last message preview (truncated to 60 chars), time of last message, and an unread count badge if `unreadCount > 0`
  - Clicking an item calls `setActiveConversation(id)`
  - Includes a "New Chat" button at the top that opens `<NewConversationDialog />`
  - Shows a skeleton loader while `isLoading` is true

- [ ] Create `src/components/chat/ConversationView.tsx`:
  - Shows a placeholder ("Select a conversation") when `activeConversationId` is null
  - Otherwise renders: `<MessageList />`, `<TypingIndicator />`, and `<MessageInput />`
  - Shows conversation name and participant count in the header

- [ ] Create `src/components/chat/MessageList.tsx`:
  - Uses `useMessages(activeConversationId)` to load messages
  - Renders messages in chronological order (oldest at top, newest at bottom)
  - Auto-scrolls to the bottom when new messages arrive (unless the user has scrolled up)
  - Implements infinite scroll at the top: triggers `loadMore()` when the user scrolls near the top, shows a spinner while loading
  - Groups consecutive messages from the same sender (show avatar only once per group)
  - Shows date separators (e.g., "Today", "Yesterday", "March 1") between messages from different days

- [ ] Create `src/components/chat/MessageBubble.tsx`:
  - Renders a single message. Own messages appear on the right (blue bubble), others on the left (gray bubble)
  - Shows sender name above the bubble (for group chats only, when it's not your message)
  - Shows timestamp below the bubble on hover
  - Renders read receipts below the last message the user sent: show avatar thumbnails of participants whose `lastReadAt >= message.createdAt`. Use a tooltip to show names on hover.
  - Handles `deletedAt !== null` by showing "[Message deleted]" in italic

- [ ] Create `src/components/chat/TypingIndicator.tsx`:
  - Reads `typingUsers[activeConversationId]` from the chat store
  - Shows "Alice is typing..." or "Alice and Bob are typing..." or "3 people are typing..." based on the number of typing users
  - Uses a CSS animation for the classic three-dot pulsing effect
  - Only renders when there is at least one typing user

- [ ] Create `src/components/chat/MessageInput.tsx`:
  - Controlled textarea that grows up to 5 lines then scrolls
  - Send on Enter (Shift+Enter for newline). Disable send button when content is empty or only whitespace.
  - On keystroke, calls `sendTyping(conversationId, true)`; uses a debounce (stop-typing after 2s of inactivity) to call `sendTyping(conversationId, false)`
  - On send: calls `sendMessage()` from `useMessages`, optimistically appends the message to the store immediately (with a `pending` status), and updates it to confirmed once the API responds. On failure, marks the message as failed and shows a retry button.
  - Clears the input and resets height after sending

- [ ] Create `src/components/chat/NewConversationDialog.tsx`:
  - A modal dialog (use the existing dialog component if available, otherwise `<dialog>` element or a simple modal)
  - Contains a user search input that calls `GET /api/users/search?q=` (assume this endpoint exists from the existing auth system, or create a simple one that queries `User` by name/email)
  - Shows search results as a selectable list with checkboxes
  - Shows a "Group name" text field that appears when more than one user is selected
  - "Start Chat" button calls `createConversation()` and navigates to the new conversation

- [ ] Add a chat icon/link in the main navigation (wherever the app's nav component lives — check `src/components/` or `src/app/layout.tsx`) that links to `/chat` and shows a notification badge with total unread count across all conversations

- [ ] Write component tests in `src/components/chat/__tests__/` for at minimum: `MessageBubble` (read receipt rendering), `TypingIndicator` (correct text for 1/2/3+ users), and `MessageInput` (send on Enter, Shift+Enter for newline, disabled state)
