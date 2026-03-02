# Frontend: 사용자 프로필 페이지

프로필 사진 업로드, 닉네임 변경, 비밀번호 변경 세 섹션으로 구성된 프로필 페이지를 구현합니다. 01~03 번 todo의 API가 완성된 후 진행하세요.

> Assumption: React + TypeScript, React Query(TanStack Query)로 서버 상태 관리, 기존 라우팅 시스템에 `/profile` 경로 추가. 전역 auth 상태에서 JWT 토큰 접근 가능 가정.

- [ ] `src/types/user.ts`에 프론트엔드용 타입 정의: `UserProfile`, `UpdateNicknameRequest`, `ChangePasswordRequest` (백엔드 타입과 동일 구조)
- [ ] `src/lib/api/userApi.ts` 구현: `fetchMyProfile()`, `updateNickname(nickname)`, `uploadAvatar(file: File)`, `changePassword(currentPassword, newPassword)` — 각 함수는 fetch + Authorization 헤더 포함, 에러 시 throw
- [ ] `useProfile` 커스텀 훅 구현 (`src/hooks/useProfile.ts`): React Query `useQuery`로 프로필 조회, `useMutation`으로 각 수정 액션 + 성공 시 쿼리 무효화(`invalidateQueries`)
- [ ] `AvatarUpload` 컴포넌트 구현 (`src/components/profile/AvatarUpload.tsx`): props `{ currentAvatarUrl: string | null, onSuccess: (newUrl: string) => void }` — 클릭 시 파일 선택 다이얼로그, 미리보기, 업로드 진행 상태 표시, 5MB 초과 시 "파일 크기는 5MB 이하여야 합니다." 표시
- [ ] `NicknameForm` 컴포넌트 구현 (`src/components/profile/NicknameForm.tsx`): 현재 닉네임 pre-fill, 변경 시 디바운스 없이 즉시 저장 버튼 노출, 성공 시 "닉네임이 변경되었습니다." 토스트, 중복 닉네임(409) 시 인풋 하단에 에러 표시
- [ ] `PasswordChangeForm` 컴포넌트 구현 (`src/components/profile/PasswordChangeForm.tsx`): 현재 비밀번호 / 새 비밀번호 / 새 비밀번호 확인 필드, 클라이언트 사이드 일치 검증, 401 응답 시 "현재 비밀번호가 올바르지 않습니다." 표시, 성공 시 폼 초기화
- [ ] `/profile` 페이지 컴포넌트 구현 (`src/pages/ProfilePage.tsx`): 세 컴포넌트를 섹션별로 배치, `useProfile` 훅으로 데이터 공급, 로딩 스켈레톤 표시
- [ ] 라우터에 `/profile` 경로 추가 + `ProtectedRoute`로 감싸기 (미인증 시 로그인 페이지로 리다이렉트)
- [ ] `src/components/profile/__tests__/NicknameForm.test.tsx` 작성: (a) 현재 닉네임이 인풋에 표시됨, (b) 중복 닉네임 에러 메시지 렌더링, (c) 성공 시 토스트 노출
- [ ] `src/components/profile/__tests__/PasswordChangeForm.test.tsx` 작성: (a) 새 비밀번호 불일치 시 제출 불가, (b) 현재 비밀번호 오류(401) 시 에러 메시지 표시, (c) 성공 시 폼 초기화