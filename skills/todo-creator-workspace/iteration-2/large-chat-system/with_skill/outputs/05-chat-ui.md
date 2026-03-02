# Build Chat UI Components (Conversation List, Message View, Composer, Read Receipts)

This todo assembles the visual layer by composing the client state hooks from todo 04 into React components. All components are pure presentational where possible, receiving data and callbacks as props to stay independently testable. Architectural assumptions: Tailwind CSS is used for styling; the layout is a two-column panel (conversation list left, active chat right) rendered at `/chat`; virtual scrolling is not required at this stage but the message list must scroll to the bottom on new messages and support infinite upward scroll for history.

- [ ] Create the page at `src/app/chat/page.tsx`:
  - Server component that fetches the initial conversation list via `fetch('/api/chat/conversations', { cache: 'no-store' })` and passes it to the `ChatLayout` client component
  - Wraps content in a `<QueryClientProvider>` and Zustand provider if needed

- [ ] Create `src/components/chat/ChatLayout.tsx` (Client Component):
  - Props: `initialConversations: ConversationWithMembers[]`
  - Calls `useConversations({ initialData })` and `useChat()`
  - Renders `<ConversationList>` on the left and `<ActiveConversation>` on the right
  - On mobile: show only the list or the active conversation (toggle via `activeConversationId`)

- [ ] Create `src/components/chat/ConversationList.tsx`:
  - Props: `conversations: ConversationWithMembers[]; activeId: string | null; onSelect: (id: string) => void`
  - Renders each conversation as a `<ConversationItem>` sorted by latest message timestamp
  - Shows unread badge (red dot with count) from `chatStore.unreadCounts`

- [ ] Create `src/components/chat/ConversationItem.tsx`:
  - Props: `conversation: ConversationWithMembers; isActive: boolean; unreadCount: number; onClick: () => void`
  - Displays: avatar(s), conversation name (or participant names for DIRECT), last message preview (truncated to 60 chars), timestamp, unread badge

- [ ] Create `src/components/chat/ActiveConversation.tsx` (Client Component):
  - Calls `useChatHistory(activeConversationId)` and `useChat()`
  - Renders `<ConversationHeader>`, `<MessageList>`, and `<MessageComposer>`
  - Calls `markAsRead` with the latest message ID when the component mounts or `activeConversationId` changes (using `useEffect`)

- [ ] Create `src/components/chat/MessageList.tsx`:
  - Props: `messages: MessageWithSender[]; currentUserId: string; onLoadMore: () => void; hasMore: boolean`
  - Uses `useRef` + `useEffect` to auto-scroll to bottom when new messages arrive
  - Renders an "Load earlier messages" button at the top that calls `onLoadMore` (triggers `useChatHistory` next-page fetch)
  - Groups messages by sender when sent within 60 seconds (collapse repeated avatar/name)

- [ ] Create `src/components/chat/MessageBubble.tsx`:
  - Props: `message: MessageWithSender; isSelf: boolean; showSenderInfo: boolean`
  - Displays: sender avatar + name (if `showSenderInfo`), message content, timestamp, read receipt indicator
  - For self-sent messages: show a checkmark icon; single check = sent, double check = read by at least one other member
  - For soft-deleted messages (`content === null`): render italic "This message was deleted" placeholder
  - Read receipt indicator data comes from `chatStore` (`updateReadReceipt` events)

- [ ] Create `src/components/chat/ReadReceiptIndicator.tsx`:
  - Props: `readers: ReadReceiptInfo[]; messageId: string`
  - Shows small avatars of members who have read up to this message (last N readers, max 5 avatars, "+N more" overflow)

- [ ] Create `src/components/chat/MessageComposer.tsx`:
  - Props: `onSend: (content: string) => void; disabled?: boolean`
  - Controlled `<textarea>` with Enter to send (Shift+Enter for newline), character counter showing remaining of 2000 limit
  - Disables send button and shows a warning when content exceeds 2000 chars
  - Clears input on successful send

- [ ] Create `src/components/chat/NewConversationModal.tsx`:
  - Modal triggered by a "+ New Chat" button in `ConversationList`
  - Form fields: type selector (DIRECT / GROUP), user search input (calls `GET /api/users/search?q=` — assume this endpoint exists), group name (visible only when type is GROUP)
  - On submit: calls `createConversation` from `useConversations`, closes modal, selects the new conversation

- [ ] Error display mapping from `ChatErrorCode` to user-facing messages:
  - `UNAUTHORIZED` → "You have been signed out. Please refresh the page."
  - `NOT_A_MEMBER` → "You are no longer a member of this conversation."
  - `MESSAGE_TOO_LONG` → "Message exceeds 2,000 character limit."
  - `CONVERSATION_NOT_FOUND` → "This conversation no longer exists."
  - All errors surface via `sonner` toast (or the project's existing toast library)

- [ ] Write tests in `src/__tests__/chat/MessageBubble.test.tsx`:
  - Self-sent message renders on the right with a checkmark icon
  - Soft-deleted message renders "This message was deleted" and not the original content
  - `ReadReceiptIndicator` shows avatars for readers whose `lastReadMessageId` >= the message's `id`

- [ ] Write tests in `src/__tests__/chat/MessageComposer.test.tsx`:
  - Pressing Enter submits the message and clears the input
  - Pressing Shift+Enter inserts a newline without submitting
  - Input over 2000 characters disables the send button and shows character count warning

- [ ] Write tests in `src/__tests__/chat/ConversationList.test.tsx`:
  - Conversations are ordered by latest message timestamp (most recent first)
  - Unread badge shows the correct count and disappears after `markAsRead` is called
