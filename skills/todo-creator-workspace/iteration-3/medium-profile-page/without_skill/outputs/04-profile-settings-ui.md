# 닉네임 및 비밀번호 변경 UI 폼 구현

프로필 페이지 내 설정 섹션에 닉네임 변경 폼과 비밀번호 변경 폼을 구현한다. 각 폼은 독립적으로 제출되며, 실시간 유효성 검증과 명확한 피드백을 제공한다. 두 폼 모두 API 응답 에러를 인라인으로 표시한다.

- [ ] `NicknameForm` 컴포넌트 생성 (`src/components/profile/NicknameForm.tsx`): props `{ currentNickname: string | null, onSuccess: (nickname: string) => void }`. 현재 닉네임이 input 초기값으로 설정됨
- [ ] 닉네임 실시간 유효성 검증: 2자 미만이면 "2자 이상 입력해주세요.", 20자 초과 시 "20자 이하로 입력해주세요.", 특수문자 포함 시 "영문, 한글, 숫자, 밑줄(_)만 사용 가능합니다."
- [ ] 닉네임 변경 제출 시 `PUT /api/users/me/nickname` 호출, 409 응답 시 "이미 사용 중인 닉네임입니다." 인라인 에러 표시
- [ ] `PasswordChangeForm` 컴포넌트 생성 (`src/components/profile/PasswordChangeForm.tsx`): props `{ onSuccess: () => void }`. 필드: 현재 비밀번호, 새 비밀번호, 새 비밀번호 확인
- [ ] 새 비밀번호 실시간 검증: 8자 미만 "8자 이상 입력해주세요.", 새 비밀번호 확인 불일치 시 "비밀번호가 일치하지 않습니다."
- [ ] 비밀번호 변경 제출 시 `PUT /api/users/me/password` 호출, 401 응답 시 현재 비밀번호 input 옆에 "현재 비밀번호가 올바르지 않습니다." 에러 표시
- [ ] 성공 시 두 폼 모두 성공 메시지 표시 후 폼 초기화. 비밀번호 폼은 모든 필드 초기화
- [ ] 비밀번호 입력 필드에 표시/숨기기 토글 버튼(눈 아이콘) 추가
- [ ] 테스트 `src/components/profile/__tests__/ProfileForms.test.tsx`: (a) 닉네임 2자 미만 시 submit 비활성화, (b) 비밀번호 불일치 시 에러 메시지, (c) API 401 시 인라인 에러, (d) 성공 시 onSuccess 콜백 호출