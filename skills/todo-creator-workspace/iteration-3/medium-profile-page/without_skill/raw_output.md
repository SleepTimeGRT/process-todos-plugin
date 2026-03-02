```01-db-schema.md
# 사용자 프로필 DB 스키마 업데이트

users 테이블에 프로필 기능에 필요한 컬럼을 추가한다. 이 스키마 변경은 이후 API 엔드포인트와 프론트엔드 작업의 기반이 되므로 가장 먼저 완료되어야 한다. avatar_url은 파일 저장소 경로(또는 외부 URL)를 저장하고, nickname은 사용자가 표시하는 이름으로 username과 별도로 관리한다.

- [ ] users 테이블에 `avatar_url VARCHAR(500) DEFAULT NULL` 컬럼 추가하는 마이그레이션 파일 작성 (예: `migrations/YYYYMMDD_add_user_profile_fields.sql`)
- [ ] users 테이블에 `nickname VARCHAR(50) DEFAULT NULL` 컬럼 추가 (동일 마이그레이션 파일에 포함)
- [ ] nickname에 고유성 제약 추가 여부 결정 — 고유하면 더 명확하지만 변경 시 충돌 처리 필요. 고유 인덱스 추가: `CREATE UNIQUE INDEX IF NOT EXISTS idx_users_nickname ON users(nickname)`
- [ ] User 모델(또는 타입 정의)에 `avatarUrl: string | null`, `nickname: string | null` 필드 추가 (예: `src/models/User.ts` 또는 `src/types/user.ts`)
- [ ] 파일 업로드 저장 위치 결정 및 문서화: 로컬 `public/uploads/avatars/` 디렉토리 사용을 기본으로 가정. 해당 디렉토리 생성 및 `.gitkeep` 추가
- [ ] 마이그레이션 실행 후 기존 users 레코드의 신규 컬럼이 NULL 상태임을 확인하는 seed/verify 스크립트 작성
```

```02-profile-api-endpoints.md
# 프로필 관련 백엔드 API 엔드포인트 구현

사용자가 프로필 사진 업로드, 닉네임 변경, 비밀번호 변경을 수행할 수 있는 REST API 3개를 구현한다. 모든 엔드포인트는 인증된 사용자만 접근 가능하며, 자신의 정보만 수정할 수 있다. 파일 업로드는 multipart/form-data 방식이며, 로컬 스토리지에 저장하는 것을 기본으로 가정한다.

- [ ] `multer` 또는 동등한 파일 업로드 미들웨어 설치 및 설정 (`src/middlewares/upload.ts`): 허용 타입 `image/jpeg`, `image/png`, `image/webp`, 최대 파일 크기 5MB, 저장 경로 `public/uploads/avatars/`, 파일명 `{userId}-{timestamp}.{ext}` 형식으로 지정
- [ ] `PUT /api/users/me/avatar` 엔드포인트 구현 (`src/routes/profile.ts`): multipart 폼에서 `avatar` 필드를 받아 저장 후 `{ avatarUrl: "/uploads/avatars/..." }` 반환. 이전 파일이 존재하면 기존 파일 삭제
- [ ] avatar 엔드포인트 유효성 검증: 파일이 없는 경우 400, 허용되지 않은 MIME 타입 400, 크기 초과 413 에러 반환
- [ ] `PUT /api/users/me/nickname` 엔드포인트 구현: body `{ nickname: string }` 받아 DB 업데이트 후 `{ nickname }` 반환. 닉네임 규칙: 2~20자, 영문/한글/숫자/밑줄만 허용
- [ ] nickname 엔드포인트 유효성 검증: 빈 값 400, 길이 초과 400, 이미 사용 중인 닉네임 409 에러 반환
- [ ] `PUT /api/users/me/password` 엔드포인트 구현: body `{ currentPassword: string, newPassword: string }` 받아 현재 비밀번호 검증 후 bcrypt로 해시하여 저장. 성공 시 `{ message: "비밀번호가 변경되었습니다." }` 반환
- [ ] password 엔드포인트 유효성 검증: currentPassword 불일치 401, newPassword가 8자 미만이거나 복잡도 미달 400 에러 반환
- [ ] 모든 엔드포인트에 JWT 인증 미들웨어 적용, 미인증 요청 시 401 반환
- [ ] 테스트 파일 `src/__tests__/profile-api.test.ts` 작성: (a) 정상 아바타 업로드 200, (b) 5MB 초과 파일 413, (c) 닉네임 중복 409, (d) 현재 비밀번호 틀림 401, (e) 미인증 요청 401
```

```03-profile-photo-upload-ui.md
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
```

```04-profile-settings-ui.md
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
```

```05-profile-page-integration.md
# 프로필 페이지 통합 및 라우팅 연결

앞서 구현한 AvatarUpload, NicknameForm, PasswordChangeForm 컴포넌트를 하나의 프로필 페이지로 조합하고, 라우팅과 초기 데이터 로딩을 연결한다. 페이지는 현재 로그인한 사용자의 프로필 정보를 불러와 각 컴포넌트에 초기값으로 전달한다.

- [ ] `GET /api/users/me` 엔드포인트가 없다면 추가: `{ id, email, nickname, avatarUrl }` 반환 (또는 기존 엔드포인트가 이 필드를 포함하도록 업데이트)
- [ ] `ProfilePage` 컴포넌트 생성 (`src/pages/ProfilePage.tsx` 또는 프레임워크에 맞는 경로): 마운트 시 `GET /api/users/me` 호출하여 초기 프로필 데이터 로드
- [ ] 로딩 중 스켈레톤 UI, 에러 시 재시도 버튼 표시
- [ ] 페이지 레이아웃: 상단 아바타 + 이메일(수정 불가) 섹션, 중간 닉네임 변경 섹션, 하단 비밀번호 변경 섹션으로 구성
- [ ] 각 폼의 `onSuccess` 콜백에서 전역 사용자 상태(Context 또는 스토어) 업데이트하여 헤더의 아바타/닉네임이 즉시 반영되도록 연결
- [ ] 프로필 페이지 라우트 등록: `/profile` 또는 `/settings/profile` 경로에 인증 가드 적용 (미인증 시 로그인 페이지로 리다이렉트)
- [ ] 페이지 타이틀 및 메타 정보 설정: "내 프로필 – [서비스명]"
- [ ] 네비게이션(헤더 또는 사이드바)에 프로필 페이지 링크 추가
- [ ] E2E 또는 통합 테스트 `src/__tests__/ProfilePage.integration.test.tsx`: (a) 페이지 로드 시 현재 닉네임이 폼에 표시, (b) 아바타 변경 후 헤더 아바타 업데이트, (c) 미인증 상태에서 프로필 접근 시 리다이렉트
```

---

총 5개의 파일이 생성됩니다. 각 파일의 역할은 다음과 같습니다:

| 파일 | 항목 수 | 내용 |
|------|--------|------|
| `01-db-schema.md` | 6개 | users 테이블에 `avatar_url`, `nickname` 컬럼 추가 및 마이그레이션 |
| `02-profile-api-endpoints.md` | 9개 | 아바타 업로드/닉네임 변경/비밀번호 변경 REST API 3개 |
| `03-profile-photo-upload-ui.md` | 8개 | 클릭&드래그 업로드, 미리보기, 로딩 상태를 가진 `AvatarUpload` 컴포넌트 |
| `04-profile-settings-ui.md` | 9개 | 실시간 유효성 검증이 포함된 닉네임/비밀번호 변경 폼 컴포넌트 |
| `05-profile-page-integration.md` | 9개 | 컴포넌트 조합, 라우팅 연결, 전역 상태 업데이트 |

> **가정 사항**: 파일 업로드는 로컬 `public/uploads/avatars/` 디렉토리 사용, JWT 인증 사용, TypeScript + React 스택. 다른 스택이라면 파일 경로와 라이브러리 이름을 조정하세요.

`/process-todos`를 실행하면 순서대로 처리됩니다.
