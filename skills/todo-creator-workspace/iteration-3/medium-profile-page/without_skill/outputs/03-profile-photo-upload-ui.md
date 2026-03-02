# 프로필 사진 업로드 UI 컴포넌트 구현

사용자가 프로필 페이지에서 아바타 이미지를 클릭하거나 드래그&드롭하여 새 사진을 업로드할 수 있는 인터랙티브 컴포넌트를 구현한다. 업로드 전 미리보기를 제공하고, 업로드 진행 중에는 로딩 상태를 표시한다.

- [ ] `AvatarUpload` 컴포넌트 생성 (`src/components/profile/AvatarUpload.tsx`): props `{ currentAvatarUrl: string | null, onSuccess: (newUrl: string) => void, userId: string }`
- [ ] 아바타 클릭 시 숨겨진 `<input type="file" accept="image/*">` 트리거 구현
- [ ] 파일 선택 후 `FileReader`로 즉시 로컬 미리보기 표시 (업로드 전에 보여주기)
- [ ] 미리보기 확인 후 "업로드" 버튼 클릭 시 `PUT /api/users/me/avatar` 호출, FormData로 전송
- [ ] 업로드 중 스피너 오버레이 표시, 완료 시 `onSuccess` 콜백 호출
- [ ] 에러 처리: 파일 크기 초과 시 "이미지는 5MB 이하여야 합니다.", 허용되지 않는 형식 시 "JPG, PNG, WebP 형식만 지원합니다." 토스트 또는 인라인 메시지 표시
- [ ] 아바타가 없을 때 기본 placeholder(이니셜 또는 기본 아이콘) 표시
- [ ] 테스트 `src/components/profile/__tests__/AvatarUpload.test.tsx`: (a) 파일 선택 시 미리보기 렌더링, (b) 업로드 성공 시 onSuccess 호출, (c) 크기 초과 시 에러 메시지 표시