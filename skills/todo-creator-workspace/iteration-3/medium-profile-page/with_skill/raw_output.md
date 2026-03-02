```01-backend-profile-api.md
# Backend: User Profile Read & Nickname Update API

사용자 프로필 조회 및 닉네임 변경 API를 구현합니다. 이 엔드포인트들은 프론트엔드 프로필 페이지의 기반이 되며, 이후 아바타 업로드·비밀번호 변경 API가 동일한 auth 미들웨어와 사용자 타입을 공유합니다.

> Assumption: JWT 기반 인증, Express + TypeScript 백엔드, ORM은 Prisma 사용 가정. DB 스키마에 `users` 테이블이 이미 존재하나 `nickname`, `avatarUrl` 컬럼은 이번 작업에서 추가.

- [ ] `prisma/schema.prisma`의 `User` 모델에 `nickname String?`과 `avatarUrl String?` 필드 추가 후 `npx prisma migrate dev --name add-user-profile-fields` 실행
- [ ] `src/types/user.ts`에 공유 타입 정의: `UserProfile { id, email, nickname, avatarUrl, createdAt }` 인터페이스와 `UpdateNicknameRequest { nickname: string }` 타입
- [ ] `src/middleware/auth.ts`에 `requireAuth` 미들웨어 구현 (없을 경우): Authorization 헤더에서 JWT 파싱 → `req.user`에 `{ id, email }` 주입, 실패 시 401 반환
- [ ] `GET /api/users/me` 엔드포인트 구현 (`src/routes/users.ts`): `requireAuth` 적용 후 DB에서 사용자 조회, `UserProfile` 형태로 응답 (password 해시 필드 제외)
- [ ] `PATCH /api/users/me/nickname` 엔드포인트 구현: 요청 바디 `{ nickname }` 검증 (2~20자, 특수문자 제한), DB 업데이트 후 업데이트된 `UserProfile` 반환
- [ ] 닉네임 중복 검사 로직 추가: 동일 닉네임 존재 시 409 Conflict + `{ error: "이미 사용 중인 닉네임입니다." }` 반환
- [ ] `src/routes/__tests__/users.test.ts` 작성: (a) 인증된 사용자가 프로필 조회 성공, (b) 인증 토큰 없을 때 401 반환, (c) 닉네임 변경 성공, (d) 중복 닉네임으로 409 반환, (e) 20자 초과 닉네임으로 400 반환
```

```02-backend-avatar-upload.md
# Backend: 프로필 사진 업로드 API

`multipart/form-data` 방식의 파일 업로드 엔드포인트를 구현합니다. 이미지 검증·리사이징 후 저장하고, 저장된 URL을 사용자 레코드에 반영합니다.

> Assumption: 파일 저장은 로컬 `public/uploads/avatars/`에 저장 (외부 스토리지 서비스 미사용). 이미지 처리는 `sharp` 라이브러리 사용. 파일명은 UUID로 생성해 충돌 방지.

- [ ] 의존성 설치: `npm install multer sharp uuid` + `npm install -D @types/multer @types/uuid`
- [ ] `src/lib/upload.ts`에 multer 설정 구현: 허용 MIME 타입(`image/jpeg`, `image/png`, `image/webp`), 최대 파일 크기 5MB, 메모리 스토리지(`memoryStorage`) 사용
- [ ] `src/lib/avatarProcessor.ts`에 이미지 처리 함수 구현: sharp로 256×256 리사이징 + `cover` 크롭, WebP 변환, `public/uploads/avatars/{uuid}.webp`에 저장, 저장 경로 반환
- [ ] `POST /api/users/me/avatar` 엔드포인트 구현 (`src/routes/users.ts`에 추가): `requireAuth` + multer 미들웨어 체인 → `avatarProcessor` 호출 → DB `avatarUrl` 업데이트 → `{ avatarUrl: "/uploads/avatars/{uuid}.webp" }` 반환
- [ ] 기존 아바타 파일 정리 로직: 새 아바타 업로드 성공 후 이전 파일이 `public/uploads/avatars/`에 존재하면 `fs.unlink`로 삭제
- [ ] Express에서 `public/` 디렉터리 정적 파일 서빙 설정 확인 (`app.use(express.static('public'))`)
- [ ] `src/routes/__tests__/avatar.test.ts` 작성: (a) 유효한 JPEG 업로드 성공 및 `avatarUrl` 반환, (b) 5MB 초과 파일 거부 (413), (c) PDF 등 허용되지 않는 형식 거부 (400), (d) 인증 없이 업로드 시도 시 401
```

```03-backend-password-change.md
# Backend: 비밀번호 변경 API

현재 비밀번호 확인 후 새 비밀번호로 변경하는 보안 엔드포인트를 구현합니다. 무차별 대입 공격 방지를 위한 rate limiting도 포함합니다.

> Assumption: bcrypt로 비밀번호 해싱, `express-rate-limit` 패키지 사용 가능 가정.

- [ ] `src/types/user.ts`에 `ChangePasswordRequest { currentPassword: string, newPassword: string }` 타입 추가
- [ ] 비밀번호 검증 규칙 함수 `validatePassword(password: string): { valid: boolean, message?: string }` 구현 (`src/lib/validation.ts`): 최소 8자, 영문+숫자 조합 필수
- [ ] `POST /api/users/me/password` 엔드포인트 구현 (`src/routes/users.ts`에 추가):
  1. `requireAuth` 미들웨어
  2. 요청 바디 `{ currentPassword, newPassword }` 검증
  3. DB에서 사용자 조회 (password 필드 포함)
  4. `bcrypt.compare`로 현재 비밀번호 검증 → 불일치 시 `401 { error: "현재 비밀번호가 올바르지 않습니다." }`
  5. `validatePassword`로 새 비밀번호 규칙 검사 → 위반 시 `400 { error: "..." }`
  6. `bcrypt.hash(newPassword, 12)`로 해싱 후 DB 업데이트
  7. `204 No Content` 반환
- [ ] 비밀번호 변경 엔드포인트에 rate limiting 적용: 동일 IP에서 15분에 5회 초과 시 429 반환 (`src/middleware/rateLimiter.ts`)
- [ ] `src/routes/__tests__/password.test.ts` 작성: (a) 올바른 현재 비밀번호로 변경 성공 (204), (b) 틀린 현재 비밀번호로 401, (c) 새 비밀번호가 규칙 미충족 시 400 + 한국어 에러 메시지, (d) 현재와 동일한 비밀번호로 변경 시도 시 400
```

```04-frontend-profile-page.md
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
```

---

총 4개의 todo 파일을 생성했습니다:

| 파일 | 항목 수 | 역할 |
|------|---------|------|
| `01-backend-profile-api.md` | 7개 | 프로필 조회 + 닉네임 변경 API, DB 마이그레이션 |
| `02-backend-avatar-upload.md` | 7개 | 파일 업로드, 이미지 리사이징, 정적 서빙 |
| `03-backend-password-change.md` | 5개 | 비밀번호 변경 + Rate limiting |
| `04-frontend-profile-page.md` | 10개 | API 클라이언트, 훅, 컴포넌트, 라우팅 |

**분리 기준:**
- 아바타 업로드는 `multipart/form-data`와 파일 시스템 처리라는 독립적인 관심사라 별도 todo로 분리했습니다
- 비밀번호 변경은 보안 민감도가 달라 rate limiting 등 별도 고려사항이 있어 분리했습니다
- 프론트엔드는 API가 모두 완성된 후 처리할 수 있도록 마지막에 배치했습니다

파일을 `docs/todos/`에 저장하고 `/process-todos`를 실행하면 순서대로 처리됩니다.
