# Config 읽기 로직에 Validation 통합

기존의 `.process-todos.json` 읽기 코드에 스키마 검증을 추가한다. 파일이 없거나 JSON parse 에러인 경우, 스키마 불일치인 경우를 각각 구분해서 처리해야 한다.

- [ ] 기존 config 읽기 함수를 찾아서 validation 단계를 추가할 위치를 파악
- [ ] JSON.parse 이후, 스키마 검증 호출을 삽입한다
- [ ] 검증 실패 시 `ValidationError` 또는 플러그인 기존 에러 패턴에 맞는 에러 객체를 throw
- [ ] 검증 성공 시 스키마에서 추론한 타입으로 반환값을 typed하게 처리
- [ ] 파일 없음(정상 케이스) vs JSON parse 실패 vs 스키마 불일치를 각각 다르게 처리