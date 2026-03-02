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