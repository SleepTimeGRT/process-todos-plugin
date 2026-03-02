# Build Chat UI Components

The user-facing chat interface. Consumes state from the hooks in todo #4. All components are presentational where possible — business logic stays in hooks.

Design assumptions documented here: slide-in panel layout (chat opens from the side without leaving the current page), message bubbles with sender avatar for group chats only, read receipts shown as "✓ Read by X" in 1:1 and "Read by 3" in group chats, typing indicator shows animated dots. No external UI library assumed — uses project's existing component system.

- [ ] Create `src/components/chat/ChatPanel.tsx` — top-level container:
  - Props: `{ isOpen: boolean, onClose: () => void }`
  - Renders `ConversationList` on the left, `MessageThread` on the right
  - Uses `useChat()` hook; passes down only necessary props to children
  - On mobile (<768px): shows either list or thread, not both (back button to return to list)
- [ ] Create `src/components/chat/ConversationList.tsx`:
  - Props: `{ conversations: Conversation[], activeId: string | null, onSelect: (id: string) => void, onNewChat: () => void }`
  - Renders each conversation as a row: avatar (group icon or user avatar), name, last message preview (truncated to 1 line), timestamp, unread badge (red circle with count if `unreadCount > 0`)
  - "New Chat" button at top triggers `NewConversationModal`
  - Search/filter input to filter visible conversations by name
- [ ] Create `src/components/chat/MessageThread.tsx`:
  - Props: `{ conversationId: string, participants: ConversationParticipant[] }`
  - Uses `useConversationMessages(conversationId)` for message data
  - Implements virtual scroll or windowing — for large message lists, only render visible messages + buffer
  - Auto-scrolls to bottom on new message if user was already at bottom; shows "↓ New messages" button if scrolled up
  - Calls `markRead()` when component is focused and visible (IntersectionObserver on last message)
  - Renders `TypingIndicator` when `typingUsers.get(conversationId)` is non-empty
- [ ] Create `src/components/chat/MessageBubble.tsx`:
  - Props: `{ message: Message, isOwnMessage: boolean, showAvatar: boolean, readBy: string[] }`
  - `showAvatar` is true only for group chats (passed from parent based on `conversation.type`)
  - Own messages: right-aligned, primary color background
  - Others' messages: left-aligned, neutral background, shows sender name above bubble in group chats
  - Deleted messages: render "[메시지가 삭제되었습니다]" in muted italic, no content
  - Read receipt below own messages: if `readBy.length === 0` → "전송됨", if `readBy.length > 0` → "읽음" (1:1) or `읽음 ${readBy.length}명` (group)
- [ ] Create `src/components/chat/MessageInput.tsx`:
  - Props: `{ conversationId: string, onSend: (content: string) => void, onTypingStart: () => void, onTypingStop: () => void }`
  - Auto-resizing textarea (min 1 row, max 4 rows), Enter to send, Shift+Enter for newline
  - Calls `onTypingStart` on first keystroke, `onTypingStop` on send or 2.5s inactivity
  - Disabled state with "연결 중..." placeholder when `isConnected === false`
  - Character limit: 2000 chars, shows counter when >1800
- [ ] Create `src/components/chat/TypingIndicator.tsx`:
  - Props: `{ userIds: string[], participants: ConversationParticipant[] }`
  - Resolves names from participants array
  - Renders: "Alice가 입력 중..." (1 user), "Alice, Bob이 입력 중..." (2), "3명이 입력 중..." (3+)
  - Animated three-dot pulse via CSS keyframes
- [ ] Create `src/components/chat/NewConversationModal.tsx`:
  - User search input (calls `GET /api/users/search?q=` with 300ms debounce)
  - Results list with avatar, name, online indicator (green dot)
  - For group chat: multi-select mode, group name input appears when 2+ selected
  - Confirm button calls `POST /api/chat/conversations` then navigates to new conversation
- [ ] Write tests in `src/components/chat/__tests__/MessageBubble.test.tsx`: (a) deleted message renders placeholder not content, (b) own message with readBy=['user2'] shows "읽음", (c) group message shows sender name above bubble, (d) read receipt shows correct count for group chats