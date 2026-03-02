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