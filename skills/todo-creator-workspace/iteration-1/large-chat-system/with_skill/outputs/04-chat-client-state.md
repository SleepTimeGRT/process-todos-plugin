# Build Client-side Chat State Management and WebSocket Hook

This todo creates the client-side data layer for the chat system: a Zustand store that holds conversation and message state, a custom React hook that manages the WebSocket connection lifecycle, and typed API client functions that talk to the routes from todo 03. The UI components in todo 05 will consume everything built here.

- [ ] Install Zustand if not already present: `npm install zustand`

- [ ] Create `src/lib/chat/api-client.ts` — typed fetch wrappers for all chat API endpoints:
  - `getConversations(cursor?: string): Promise<ConversationListResponse>`
  - `createConversation(params: CreateConversationParams): Promise<Conversation>`
  - `getMessages(conversationId: string, cursor?: string): Promise<MessageListResponse>`
  - `sendMessage(conversationId: string, content: string): Promise<Message>`
  - `addParticipant(conversationId: string, userId: string): Promise<void>`
  - `removeParticipant(conversationId: string, userId: string): Promise<void>`
  All functions should throw a typed `ChatApiError` on non-2xx responses.

- [ ] Define shared TypeScript types in `src/lib/chat/types.ts`:
  ```ts
  export interface Conversation { id: string; name: string | null; isGroup: boolean; participants: Participant[]; lastMessage: Message | null; unreadCount: number; }
  export interface Message { id: string; conversationId: string; content: string; sender: Participant; createdAt: string; deletedAt: string | null; }
  export interface Participant { id: string; name: string; image: string | null; lastReadAt: string | null; }
  ```

- [ ] Create `src/store/chat-store.ts` using Zustand. State shape:
  ```ts
  interface ChatState {
    conversations: Conversation[];
    messagesByConversation: Record<string, Message[]>;
    activeConversationId: string | null;
    typingUsers: Record<string, string[]>; // conversationId → userId[]
    // actions
    setConversations: (convs: Conversation[]) => void;
    prependMessages: (conversationId: string, messages: Message[]) => void;
    appendMessage: (message: Message) => void;
    setActiveConversation: (id: string | null) => void;
    updateUnreadCount: (conversationId: string, count: number) => void;
    setTypingUser: (conversationId: string, userId: string, isTyping: boolean) => void;
    markConversationRead: (conversationId: string, userId: string, lastReadAt: string) => void;
  }
  ```
  Use `immer` middleware for ergonomic nested updates (install `npm install immer`).

- [ ] Create `src/hooks/use-chat-socket.ts` — a React hook that manages the WebSocket connection:
  - Connects to `ws://` (or `wss://` in production) on mount
  - Handles reconnection with exponential backoff (max 5 retries)
  - On `NEW_MESSAGE` event: calls `appendMessage` on the store; if the message is in the active conversation, immediately sends `MARK_READ` back via WS
  - On `READ_RECEIPT` event: calls `markConversationRead` on the store
  - On `USER_TYPING` event: calls `setTypingUser` on the store, auto-clears after 3 seconds
  - Exposes `sendTyping(conversationId, isTyping)` and `sendMarkRead(conversationId)` functions
  - Returns `{ isConnected, sendTyping, sendMarkRead }`

- [ ] Create `src/hooks/use-messages.ts` — a hook that handles paginated message loading for a conversation:
  - Fetches the first page of messages on mount (when `conversationId` changes)
  - Exposes `loadMore()` function for infinite scroll (loads next cursor)
  - Returns `{ messages, isLoading, hasMore, loadMore }`

- [ ] Create `src/hooks/use-conversations.ts` — a hook that loads and manages the conversation list:
  - Loads conversations on mount, stores them in the Zustand store
  - Returns `{ conversations, isLoading, createConversation, activeConversationId, setActiveConversation }`

- [ ] Write unit tests for the Zustand store actions in `src/store/__tests__/chat-store.test.ts`

- [ ] Write tests for `use-chat-socket.ts` using `@testing-library/react` with a mock WebSocket class that simulates server events
