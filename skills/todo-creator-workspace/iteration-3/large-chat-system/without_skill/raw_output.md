```01-websocket-infrastructure.md
# WebSocket 인프라 구축

WebSocket을 선택한 이유: 채팅은 클라이언트↔서버 간 양방향 통신이 필수입니다. SSE는 서버→클라이언트 단방향이라 메시지 전송 시 별도 HTTP 요청이 필요하여 채팅에 적합하지 않습니다. WebSocket은 단일 연결로 양방향 실시간 통신을 지원하며, 읽음 표시·타이핑 인디케이터 등 이벤트 푸시에도 최적입니다.

- [ ] WebSocket 서버 라이브러리 선택 및 설치 (예: `ws`, `socket.io`, 또는 언어별 동등 라이브러리)
- [ ] WebSocket 서버 엔드포인트 생성 (`/ws` 또는 `/chat`)
- [ ] 연결 인증 미들웨어 구현 (JWT 또는 세션 토큰 검증)
- [ ] 연결 풀 관리 구조 설계 (userId → WebSocket 인스턴스 매핑)
- [ ] 클라이언트 재연결 로직 구현 (exponential backoff)
- [ ] heartbeat / ping-pong 메커니즘으로 연결 유지
- [ ] WebSocket 연결 이벤트 로깅 (connect, disconnect, error)
- [ ] 수평 확장을 위한 Redis Pub/Sub 어댑터 연동 (다중 서버 인스턴스 대비)
```

```02-database-schema.md
# 채팅 데이터베이스 스키마 설계

채팅 시스템의 핵심 데이터 모델을 정의합니다. 1:1 채팅과 그룹 채팅을 통합된 `conversation` 모델로 관리하면 코드 중복을 줄이고 읽음 표시 등 공통 기능을 재사용할 수 있습니다.

- [ ] `conversations` 테이블 생성 (id, type: 'direct'|'group', name, created_at)
- [ ] `conversation_members` 테이블 생성 (conversation_id, user_id, joined_at, role: 'admin'|'member')
- [ ] `messages` 테이블 생성 (id, conversation_id, sender_id, content, message_type, created_at, deleted_at)
- [ ] `message_reads` 테이블 생성 (message_id, user_id, read_at) — 읽음 표시용
- [ ] `messages.conversation_id` 및 `messages.created_at`에 복합 인덱스 추가
- [ ] `message_reads`에 `(message_id, user_id)` 유니크 인덱스 추가
- [ ] 소프트 삭제 지원 (messages.deleted_at nullable)
- [ ] 대용량 메시지 이력을 위한 파티셔닝 또는 아카이빙 전략 문서화
```

```03-direct-messaging.md
# 1:1 채팅 구현

두 사용자 간의 직접 메시지 기능을 구현합니다. 대화방은 두 사용자 조합으로 유일하게 식별되며, 이미 존재하는 대화방은 재사용합니다.

- [ ] "대화 시작 또는 조회" API 엔드포인트 구현 (`POST /conversations/direct`)
- [ ] 두 userId로 기존 1:1 대화방 조회 로직 구현 (중복 생성 방지)
- [ ] 메시지 전송 WebSocket 이벤트 핸들러 구현 (`chat:send`)
- [ ] 수신자가 온라인일 때 WebSocket으로 실시간 전달
- [ ] 수신자가 오프라인일 때 푸시 알림 발송 (FCM/APNs 연동)
- [ ] 대화방별 메시지 목록 페이지네이션 API (`GET /conversations/:id/messages?cursor=`)
- [ ] 사용자의 전체 대화 목록 API (최신 메시지 및 읽지 않은 수 포함)
- [ ] 메시지 삭제 기능 (본인 메시지만, 소프트 삭제)
```

```04-group-chat.md
# 그룹 채팅 구현

여러 사용자가 참여하는 그룹 대화방 기능을 구현합니다. 그룹 관리(초대, 강퇴, 권한)와 실시간 브로드캐스팅이 핵심입니다.

- [ ] 그룹 대화방 생성 API (`POST /conversations/group`, 이름·초기 멤버 포함)
- [ ] 그룹에 멤버 초대 API (`POST /conversations/:id/members`)
- [ ] 멤버 강퇴 API (`DELETE /conversations/:id/members/:userId`, admin만 가능)
- [ ] 그룹 이름/설명 수정 API (admin 권한 확인)
- [ ] 그룹 나가기 API (마지막 admin이 나갈 경우 처리 로직 포함)
- [ ] 메시지 전송 시 온라인 멤버 전체에게 WebSocket 브로드캐스트
- [ ] 오프라인 멤버에게 푸시 알림 일괄 발송
- [ ] 입장/퇴장 시스템 메시지 자동 생성 (예: "홍길동님이 입장했습니다")
- [ ] 멤버 목록 및 온라인 상태 조회 API
```

```05-read-receipts.md
# 읽음 표시 시스템

메시지 읽음 여부를 실시간으로 추적하고 표시하는 기능을 구현합니다. 1:1 채팅에서는 "읽음" 표시, 그룹 채팅에서는 읽은 인원 수를 보여줍니다.

- [ ] 대화방 진입 시 모든 미읽음 메시지를 읽음으로 일괄 처리하는 API (`POST /conversations/:id/read`)
- [ ] 개별 메시지 읽음 처리 WebSocket 이벤트 핸들러 (`chat:read`)
- [ ] 읽음 처리 후 대화 상대방에게 `chat:read_receipt` 이벤트 브로드캐스트
- [ ] 1:1 채팅: 메시지별 읽음/안읽음 상태 반환 API
- [ ] 그룹 채팅: 메시지별 읽은 멤버 수 반환 API
- [ ] 대화 목록에서 읽지 않은 메시지 수(badge) 실시간 업데이트
- [ ] 앱 포커스 이벤트와 연동하여 화면에 보이는 메시지 자동 읽음 처리
- [ ] 읽음 상태 집계 쿼리 성능 최적화 (N+1 방지)
```

```06-frontend-chat-ui.md
# 채팅 프론트엔드 UI 구현

WebSocket 연결 관리부터 메시지 렌더링까지 채팅 UI 전체를 구현합니다. 실시간 업데이트와 자연스러운 UX가 핵심입니다.

- [ ] WebSocket 클라이언트 연결 관리 훅/서비스 구현 (인증 토큰 자동 첨부)
- [ ] 대화 목록 화면 구현 (최신 메시지 미리보기, 읽지 않은 메시지 badge)
- [ ] 채팅방 화면 구현 (메시지 버블, 발신자 구분, 시간 표시)
- [ ] 가상 스크롤 또는 무한 스크롤로 이전 메시지 로딩
- [ ] 새 메시지 수신 시 스크롤 자동 하단 이동 (본인이 하단에 있을 때만)
- [ ] 1:1 채팅 메시지에 읽음/안읽음 표시 렌더링
- [ ] 그룹 채팅 메시지에 읽은 인원 수 표시
- [ ] 타이핑 인디케이터 구현 (선택 사항, WebSocket `chat:typing` 이벤트)
- [ ] 그룹 채팅 멤버 관리 UI (초대, 강퇴, 나가기)
- [ ] 연결 끊김 상태 배너 및 재연결 중 UI 표시
```
