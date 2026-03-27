# 작업 보고서 - 2026-03-27 (Work12)

## 작업 내용: 서버 배포 ENOTEMPTY 오류 재발 - 근본 원인 패치

---

## 문제

이전 작업(Work11)에서 `.build` 삭제로 임시 해결했으나 동일 오류 재발:

```
Error: ENOTEMPTY: directory not empty, rmdir '/Users/yong/Desktop/MongleServer/.build/node_modules'
```

---

## 근본 원인 분석

단순한 `.DS_Store` 존재 문제가 아니라 **macOS 파일시스템 데몬의 race condition**:

1. `rimrafSync`가 `.DS_Store`를 삭제
2. macOS Finder/Spotlight 데몬이 즉시 `.DS_Store`를 재생성
3. `rmdirSync`로 부모 디렉토리 삭제 시도 → ENOTEMPTY 오류

`serverless-plugin-typescript` v2.1.5 (최신)에 번들된 `fs-extra` v7.0.1의 `rimrafSync`는
파일을 하나씩 삭제 후 `rmdirSync`를 호출하는 방식이라 이 race condition에 취약.

---

## 해결 방법

### 패치 파일
`node_modules/serverless-plugin-typescript/node_modules/fs-extra/lib/remove/rimraf.js`

### 내용
`rimrafSync` 함수를 Node.js 14.14+의 네이티브 `fs.rmSync({ recursive: true, force: true })`로 교체:

```js
// 파일 끝 부분에 추가
const _nativeFs = require('fs')
if (typeof _nativeFs.rmSync === 'function') {
  rimrafSync = function (p, options) {
    try {
      _nativeFs.rmSync(p, { recursive: true, force: true })
    } catch (er) {
      if (er.code !== 'ENOENT') throw er
    }
  }
}
```

Node.js의 네이티브 `rmSync`는 커널 레벨에서 재귀 삭제를 처리하므로 macOS race condition에 영향 없음.

---

## 주의사항

이 패치는 `node_modules` 내부 파일 수정이므로 `npm install` 실행 시 초기화됨.
재발 시 동일한 패치를 다시 적용하거나, 아래 스크립트로 자동화 가능:

```bash
# postinstall 스크립트로 자동 재적용 (package.json scripts에 추가)
"postinstall": "node scripts/patch-rimraf.js"
```

---

## 수정 파일

- `node_modules/serverless-plugin-typescript/node_modules/fs-extra/lib/remove/rimraf.js` — rimrafSync 패치
