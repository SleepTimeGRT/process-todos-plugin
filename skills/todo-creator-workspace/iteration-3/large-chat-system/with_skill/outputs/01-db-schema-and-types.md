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