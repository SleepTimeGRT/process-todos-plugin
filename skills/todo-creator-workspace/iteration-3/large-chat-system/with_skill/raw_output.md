**WebSocket 선택 이유:** 채팅은 양방향 통신이 필수입니다. SSE는 서버→클라이언트 단방향이라 메시지 전송에 별도 HTTP 요청이 필요하지만, WebSocket은 단일 연결로 송수신이 모두 가능합니다. 채팅 시스템에는 WebSocket이 명확한 선택입니다.

기능을 5개의 레이어로 분리합니다: DB 스키마 → WS 서버 → REST API → 클라이언트 상태 → UI

```01-db-schema-and-types.md
# Set Up Chat Database Schema and TypeScript Types

This is the foundation for the entire chat system. All other layers depend on these tables and types being correct first. We use a `last_read_at` approach on participants instead of per-message read receipts — this is O(1) to check rather than O(n messages), and is how WhatsApp and Slack implement it internally.

WebSocket is chosen over SSE because chat requires bidirectional communication: SSE only handles server→client pushes, requiring a separate HTTP channel for sending. WebSocket handles both directions on a single persistent connection.

- [ ] Create migration file `db/migrations/YYYYMMDD_create_chat_tables.sql` with the following tables:
  - `conversations`: `id UUID PK`, `type VARCHAR CHECK IN ('direct','group')`, `name VARCHAR NULLABLE` (only for group chats), `created_by UUID FK users`, `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ`
  - `conversation_participants`: `conversation_id UUID FK conversations`, `user_id UUID FK users`, `joined_at TIMESTAMPTZ`, `last_read_at TIMESTAMPTZ DEFAULT NOW()`, `is_admin BOOLEAN DEFAULT FALSE`, PRIMARY KEY `(conversation_id, user_id)`
  - `messages`: `id UUID PK DEFAULT gen_random_uuid()`, `conversation_id UUID FK conversations`, `sender_id UUID FK users`, `content TEXT NOT NULL`, `type VARCHAR DEFAULT 'text' CHECK IN ('text','image','system')`, `created_at TIMESTAMPTZ DEFAULT NOW()`, `deleted_at TIMESTAMPTZ NULLABLE`
- [ ] Add indexes: `messages(conversation_id, created_at DESC)` for paginated history, `conversation_participants(user_id)` for listing a user's conversations, `conversation_participants(conversation_id, last_read_at)` for unread counts
- [ ] Define TypeScript types in `src/lib/chat/types.ts`:
  ```ts
  export type ConversationType = 'direct' | 'group';

  export interface Conversation {
    id: string;
    type: ConversationType;
    name: string | null;
    createdBy: string;
    createdAt: Date;
    updatedAt: Date;
    // Joined fields for API responses:
    participants?: ConversationParticipant[];
    lastMessage?: Message | null;
    unreadCount?: number;
  }

  export interface ConversationParticipant {
    conversationId: string;
    userId: string;
    joinedAt: Date;
    lastReadAt: Date;
    isAdmin: boolean;
    // Joined:
    user?: Pick<User, 'id' | 'name' | 'avatarUrl' | 'isOnline'>;
  }

  export interface Message {
    id: string;
    conversationId: string;
    senderId: string;
    content: string;
    type: 'text' | 'image' | 'system';
    createdAt: Date;
    deletedAt: Date | null;
    // Joined:
    sender?: Pick<User, 'id' | 'name' | 'avatarUrl'>;
    readBy?: string[]; // userIds who have read (derived from last_read_at)
  }
  ```
- [ ] Define WebSocket event discriminated unions in `src/lib/chat/ws-types.ts`:
  ```ts
  // Server → Client events
  export type WsServerEvent =
    | { type: 'message:new'; payload: Message }
    | { type: 'message:deleted'; payload: { messageId: string; conversationId: string } }
    | { type: 'conversation:updated'; payload: Conversation }
    | { type: 'participant:joined'; payload: { conversationId: string; participant: ConversationParticipant } }
    | { type: 'participant:left'; payload: { conversationId: string; userId: string } }
    | { type: 'typing:start'; payload: { conversationId: string; userId: string } }
    | { type: 'typing:stop'; payload: { conversationId: string; userId: string } }
    | { type: 'read:updated'; payload: { conversationId: string; userId: string; lastReadAt: string } }
    | { type: 'user:online'; payload: { userId: string } }
    | { type: 'user:offline'; payload: { userId: string } };

  // Client → Server events
  export type WsClientEvent =
    | { type: 'message:send'; payload: { conversationId: string; content: string; type?: 'text' | 'image' } }
    | { type: 'message:delete'; payload: { messageId: string } }
    | { type: 'typing:start'; payload: { conversationId: string } }
    | { type: 'typing:stop'; payload: { conversationId: string } }
    | { type: 'read:mark'; payload: { conversationId: string } };
  ```
- [ ] Write tests in `src/lib/chat/__tests__/types.test.ts`: (a) WsServerEvent union is exhaustive with a type guard helper, (b) Message.readBy is correctly derived from participant lastReadAt timestamps in a helper function `getReadBy(message: Message, participants: ConversationParticipant[]): string[]`
```

```02-websocket-server.md
# Implement WebSocket Server with Connection and Room Management

This layer is the real-time backbone of the chat system. It manages persistent WebSocket connections, routes events between users, and handles presence (online/offline). It depends on the types from todo #1.

Design decisions documented here: (1) Connections are stored in a Map keyed by userId — one user can have multiple tabs, so we store `Map<userId, Set<WebSocket>>`. (2) Rooms mirror conversation IDs — when a message arrives for conversationId X, we look up all participants of X and push to their active connections. (3) Typing indicators are NOT persisted to DB — they exist only in memory with a 3-second auto-expire timer.

- [ ] Install dependencies: `npm install ws` and `npm install -D @types/ws`
- [ ] Create `src/lib/chat/connection-manager.ts` — a singleton `ConnectionManager` class:
  - `private connections = new Map<string, Set<WebSocket>>()` (userId → active sockets)
  - `add(userId: string, ws: WebSocket): void` — registers connection, sets up cleanup on `ws.on('close', ...)`
  - `remove(userId: string, ws: WebSocket): void` — removes socket, if Set is now empty emits `user:offline` to relevant conversations
  - `send(userId: string, event: WsServerEvent): void` — sends to all sockets for that user
  - `broadcast(userIds: string[], event: WsServerEvent): void` — sends to multiple users (deduplicates)
  - `isOnline(userId: string): boolean`
- [ ] Create `src/lib/chat/ws-server.ts` — sets up the WebSocket server:
  - Attach to existing HTTP server: `new WebSocketServer({ server: httpServer })`
  - On connection: authenticate via JWT from query param `?token=...` (extract userId), call `connectionManager.add(userId, ws)`, broadcast `user:online` to contacts
  - On message: parse JSON, validate shape against `WsClientEvent`, route to appropriate handler
  - Wrap all handlers in try/catch; on error send `{ type: 'error', payload: { message: string } }` back to client
- [ ] Create `src/lib/chat/ws-handlers.ts` — one exported async function per client event type:
  - `handleSendMessage(userId, payload)`: validate user is participant of conversation → insert message into DB → update `conversations.updated_at` → call `broadcastToConversation(conversationId, { type: 'message:new', payload: message })`
  - `handleDeleteMessage(userId, payload)`: verify sender === userId → soft-delete (set deleted_at) → broadcast `message:deleted`
  - `handleMarkRead(userId, payload)`: UPDATE conversation_participants SET last_read_at = NOW() → broadcast `read:updated` to conversation participants
  - `handleTypingStart/Stop(userId, payload)`: maintain `Map<conversationId, Map<userId, NodeJS.Timeout>>` — on start, set 3s timeout that auto-fires stop; broadcast typing event to other participants only (not sender)
- [ ] Create helper `broadcastToConversation(conversationId: string, event: WsServerEvent)` in `ws-server.ts`: queries `conversation_participants` for all userIds in that conversation, calls `connectionManager.broadcast(userIds, event)`
- [ ] Write tests in `src/lib/chat/__tests__/ws-handlers.test.ts` using mock WebSocket and mock DB: (a) handleSendMessage rejects if user is not a participant, (b) handleMarkRead updates last_read_at and broadcasts read:updated, (c) typing indicator auto-stops after 3 seconds, (d) deleted message sets deleted_at and does not expose content in broadcast
```

```03-chat-rest-api.md
# Implement Chat REST API Endpoints

REST API for operations that don't need real-time delivery: fetching history, creating conversations, managing group participants. WebSocket handles live events; REST handles initial load and management actions. Depends on DB schema from todo #1.

Pagination uses cursor-based approach (by message ID / created_at) rather than offset — this prevents the "shifting results" problem when new messages arrive during pagination.

- [ ] Create `src/routes/chat.ts` (or equivalent router file for your framework) and mount at `/api/chat`
- [ ] `GET /api/chat/conversations` — list authenticated user's conversations, ordered by `updated_at DESC`:
  - Join with `conversation_participants` (filter by current userId), `messages` (latest message subquery), `users` (participant info)
  - Include `unread_count` per conversation: count of messages where `created_at > last_read_at` for current user
  - Response: `{ conversations: Conversation[] }` with `lastMessage` and `unreadCount` populated
- [ ] `POST /api/chat/conversations` — create a new conversation:
  - Body: `{ type: 'direct' | 'group', participantIds: string[], name?: string }`
  - For `direct`: check if a direct conversation already exists between these two users — if so, return existing (idempotent). Block if `participantIds.length !== 1`.
  - For `group`: require `name`, require `participantIds.length >= 2`
  - Always add the creator as a participant with `is_admin: true`
  - Insert system message: `"[Name] created this group"` for group chats
  - Response: `{ conversation: Conversation }` with participants populated
- [ ] `GET /api/chat/conversations/:id/messages` — paginated message history:
  - Query params: `cursor?: string` (message id), `limit?: number` (default 50, max 100)
  - If cursor provided: `WHERE created_at < (SELECT created_at FROM messages WHERE id = $cursor)`
  - Join with sender user info
  - Derive `readBy` for each message: list of participant userIds whose `last_read_at >= message.created_at`
  - Response: `{ messages: Message[], nextCursor: string | null }`
- [ ] `POST /api/chat/conversations/:id/participants` — add users to group chat:
  - Require caller to be `is_admin` of the conversation
  - Body: `{ userIds: string[] }`
  - Insert into `conversation_participants`, emit WS event `participant:joined` for each new member
  - Insert system message: `"[Admin] added [User] to the group"`
- [ ] `DELETE /api/chat/conversations/:id/participants/:userId` — leave or remove from group:
  - User can remove themselves; admin can remove others
  - Delete from `conversation_participants`
  - Emit WS event `participant:left`
  - If last participant leaves, mark conversation as archived (add `archived_at` column)
- [ ] `GET /api/users/search?q=` — search users by name/email to start a new chat:
  - Exclude current user from results
  - Return: `{ users: Array<{ id, name, avatarUrl, isOnline }> }` (isOnline from ConnectionManager)
  - Limit to 20 results
- [ ] Write tests in `src/routes/__tests__/chat.test.ts`: (a) POST /conversations with type=direct is idempotent — calling twice returns same conversation, (b) GET /conversations/:id/messages cursor pagination returns correct page, (c) non-participant cannot fetch messages (403), (d) non-admin cannot add participants to group (403)
```

```04-client-websocket-and-state.md
# Implement Client-Side WebSocket Connection and Chat State

This layer manages the WebSocket lifecycle on the frontend and provides the chat state that UI components consume. It's the bridge between the server's real-time events and React rendering. Depends on WS event types from todo #1.

Key decisions documented here: (1) Single WebSocket connection per user session — not per conversation. The server uses conversation rooms for routing. (2) Optimistic updates — messages appear instantly in the UI, then get confirmed/replaced when the server echoes back `message:new`. (3) Typing indicators live in ephemeral state (not persisted), auto-cleared after 4 seconds of no update.

- [ ] Create `src/lib/chat/ws-client.ts` — a class `ChatWebSocketClient`:
  - Constructor takes `token: string` and `onEvent: (event: WsServerEvent) => void`
  - `connect()`: creates `new WebSocket(wsUrl + '?token=' + token)`, sets up reconnection logic (exponential backoff, max 5 retries)
  - `send(event: WsClientEvent): void` — JSON-serializes and sends; queues if not yet connected
  - `disconnect()`: closes connection and clears reconnect timers
  - Exports a singleton factory: `getChatClient(token)` — returns existing or creates new instance
- [ ] Create `src/stores/chatStore.ts` using your project's state management library (Zustand/Redux/etc.):
  - State shape:
    ```ts
    interface ChatState {
      conversations: Map<string, Conversation>;       // conversationId → Conversation
      messages: Map<string, Message[]>;               // conversationId → messages (sorted ASC)
      activeConversationId: string | null;
      typingUsers: Map<string, Set<string>>;          // conversationId → Set of userIds typing
      onlineUsers: Set<string>;                       // Set of online userIds
      optimisticMessages: Map<string, Message>;       // tempId → optimistic message
      isConnected: boolean;
    }
    ```
  - Actions: `setActiveConversation`, `addMessage`, `addOptimisticMessage`, `confirmOptimisticMessage(tempId, realMessage)`, `deleteMessage`, `updateReadStatus`, `setTyping`, `setOnline/Offline`
  - `handleWsEvent(event: WsServerEvent)` — dispatches incoming events to appropriate actions
- [ ] Create `src/hooks/useChat.ts`:
  - Initializes `ChatWebSocketClient` on mount, connects with auth token, calls `store.handleWsEvent` on events
  - Exposes: `{ conversations, sendMessage, markRead, startTyping, stopTyping, isConnected }`
  - `sendMessage(conversationId, content)`: adds optimistic message with `tempId = crypto.randomUUID()`, sends WS event `message:send`; on receiving `message:new` with matching content+sender, replaces optimistic message
  - `markRead(conversationId)`: debounced 500ms — calls WS `read:mark` to avoid flooding on scroll
  - `startTyping/stopTyping`: calls WS events; `startTyping` sets a 2.5s local timer to auto-call `stopTyping`
- [ ] Create `src/hooks/useConversationMessages.ts`:
  - Takes `conversationId: string`
  - Fetches initial page via `GET /api/chat/conversations/:id/messages` on mount
  - Exposes `{ messages, loadMore, hasMore, isLoading }`
  - `loadMore()` uses the last message's ID as cursor for next page fetch
  - Merges fetched historical messages with live messages from store (dedup by id)
- [ ] Write tests in `src/hooks/__tests__/useChat.test.ts`: (a) optimistic message appears before server confirmation, (b) optimistic message is replaced (not duplicated) when server confirms, (c) markRead is debounced and not called more than once per 500ms window, (d) WebSocket reconnects after unexpected close
```

```05-chat-ui-components.md
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
```

---

★ Insight ─────────────────────────────────────
**왜 5개 레이어로 분리했는가?** DB 스키마가 변경되면 그 위의 모든 레이어가 영향받습니다. 순서를 강제하는 번호 접두사(01~05)는 `process-todos`가 병렬 처리 대신 순차 처리를 하도록 유도합니다.

**`last_read_at` vs 메시지별 읽음 테이블:** 메시지별 읽음 테이블(`message_read_receipts`)은 직관적이지만, 1000명의 그룹 채팅에서 1000개 메시지면 1,000,000 행이 됩니다. `last_read_at` 방식은 "이 타임스탬프 이전 모든 메시지 = 읽음"으로 단순화해 참여자 수에 선형 비례합니다.

**Optimistic Update 패턴:** 메시지가 서버 왕복(~100ms)을 기다리면 입력 후 지연이 느껴집니다. 임시 ID로 즉시 UI에 표시하고 서버 확인 시 교체하는 패턴은 WhatsApp, iMessage가 사용하는 방식입니다.
─────────────────────────────────────────────────

총 **5개 파일** 생성됨:

| 파일 | 항목 수 | 설명 |
|------|---------|------|
| `01-db-schema-and-types.md` | 5개 | DB 테이블, TypeScript 타입, WS 이벤트 유니온 |
| `02-websocket-server.md` | 5개 | WS 서버, 연결 관리자, 이벤트 핸들러 |
| `03-chat-rest-api.md` | 7개 | 대화/메시지/참여자/유저 검색 REST API |
| `04-client-websocket-and-state.md` | 5개 | WS 클라이언트, 채팅 스토어, React 훅 |
| `05-chat-ui-components.md` | 8개 | ChatPanel, 메시지 스레드, 입력창, 타이핑 표시 |

`/process-todos`를 실행하면 01번부터 순서대로 처리됩니다.
