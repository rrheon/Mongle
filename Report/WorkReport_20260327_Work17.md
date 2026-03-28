# 서버 배포 오류 수정 (ENOTEMPTY)

**날짜**: 2026-03-27
**작업 범위**: Server (`node_modules/serverless-plugin-typescript` 패치)

---

## 원인

```
Error: ENOTEMPTY, Directory not empty: /Users/yong/Desktop/MongleServer/.build
    at Object.rmSync (node:fs:1235:18)
    at Object.rimrafSync [as removeSync] (...serverless-plugin-typescript/.../rimraf.js:319:17)
```

### 상세

- Node.js 24에서 `.build` 디렉토리 삭제 시 `rmSync`가 `ENOTEMPTY` 오류 발생
- `.build` 내 `.DS_Store` 파일이 macOS 확장 속성(`@`)을 가지고 있어 삭제 실패
- `serverless-plugin-typescript` 내 `rimraf.js` 패치 코드가 `ENOENT`만 무시하고 `ENOTEMPTY`는 re-throw

```javascript
// 기존 코드 — ENOTEMPTY를 처리하지 않음
} catch (er) {
  if (er.code !== 'ENOENT') throw er  // ENOTEMPTY 발생 시 throw
}
```

---

## 수정 내용

### 1. `rimraf.js` 패치 수정
`serverless-plugin-typescript/node_modules/fs-extra/lib/remove/rimraf.js`

`ENOTEMPTY` 발생 시 Node.js native `rmSync` 대신 원래 recursive rimraf 구현으로 fallback:

```javascript
} catch (er) {
  if (er.code === 'ENOENT') return
  if (er.code === 'ENOTEMPTY') {
    _originalRimrafSync(p, options)  // fallback to recursive implementation
    return
  }
  throw er
}
```

### 2. 기존 `.build` 디렉토리 삭제
`rm -rf .build`

---

## 주의사항

`node_modules` 내 파일을 직접 수정했으므로 `npm install` 시 초기화됩니다.
이 경우 아래 방법으로 재배포 전 `.build`를 수동 삭제하거나:
```bash
rm -rf .build && npx serverless deploy
```

또는 `package.json`에 스크립트 추가를 권장합니다:
```json
"scripts": {
  "deploy:dev": "rm -rf .build && npx serverless deploy --stage dev",
  "deploy:prod": "rm -rf .build && npx serverless deploy --stage prod"
}
```
