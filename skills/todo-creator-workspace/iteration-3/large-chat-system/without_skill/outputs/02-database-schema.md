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