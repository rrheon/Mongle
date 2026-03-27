# 작업 보고서 - 2026-03-27 (Work11)

## 작업 내용: 서버 배포 ENOTEMPTY 오류 수정

---

## 문제

`npx serverless deploy` 실행 시 아래 오류 발생:

```
Error: ENOTEMPTY: directory not empty, rmdir '/Users/yong/Desktop/MongleServer/.build/node_modules/rxjs'
```

---

## 원인 분석

macOS가 디렉토리 접근 시 자동으로 `.DS_Store` 파일을 생성하는데,
`serverless-plugin-typescript` 내부에서 사용하는 구버전 `fs-extra`의 `rimrafSync`가
`.DS_Store`가 포함된 디렉토리를 삭제하지 못해 오류가 발생.

실제로 `.build/node_modules/rxjs` 내부 확인 결과:
```
drwxr-xr-x  3  yong  staff  96   3월 27 17:23 .
drwxr-xr-x  154 yong staff 4928  3월 27 17:23 ..
-rw-r--r--@ 1  yong  staff  6148 3월 27 17:23 .DS_Store  ← 원인
```

---

## 해결 방법

### 즉시 조치
`.build` 디렉토리 수동 삭제:
```bash
rm -rf /Users/yong/Desktop/MongleServer/.build
```

### 영구 조치
`package.json`의 deploy 스크립트에 사전 정리 단계 추가:

```json
"deploy:dev": "rm -rf .build && serverless deploy --stage dev",
"deploy:prod": "rm -rf .build && serverless deploy --stage prod"
```

이후 배포 시 `.build` 잔여 파일로 인한 동일 오류 재발 방지.

---

## 수정 파일

- `/Users/yong/Desktop/MongleServer/package.json` — deploy 스크립트 수정
