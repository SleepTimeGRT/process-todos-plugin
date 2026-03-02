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