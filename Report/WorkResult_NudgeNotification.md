# 작업 결과 보고

## 작업 일자
2026-03-21

---

## 재촉하기 알림 수신 불가 버그

### 원인
`NotificationService`의 `getNotifications` / `markAsRead` / `markAllAsRead` 메서드가
JWT에서 꺼낸 **OAuth `userId`** (예: `"kakao:4799026828"`)로 알림을 조회했으나,
`Notification.userId` 컬럼은 `User.id` (**UUID**, Primary Key) FK를 저장하는 필드.

`NudgeService.sendNudge`에서는 알림을 올바르게 `target.id` (UUID)로 저장했지만,
조회 시 `"kakao:xxx"` 문자열로 검색하므로 항상 빈 결과가 반환됨.

### 수정 내용
**파일**: `FamTreeServer/src/services/NotificationService.ts`

세 메서드 모두 OAuth `authUserId`를 받아 `User.id` (UUID)를 먼저 조회한 뒤,
해당 UUID로 알림 테이블을 검색하도록 수정:

```typescript
// getNotifications
const user = await prisma.user.findUnique({ where: { userId: authUserId } });
if (!user) return [];
const items = await prisma.notification.findMany({ where: { userId: user.id }, ... });

// markAsRead
const user = await prisma.user.findUnique({ where: { userId: authUserId } });
await prisma.notification.updateMany({ where: { id: notificationId, userId: user.id }, ... });

// markAllAsRead
const user = await prisma.user.findUnique({ where: { userId: authUserId } });
await prisma.notification.updateMany({ where: { userId: user.id, isRead: false }, ... });
```

### 빌드 확인
- 서버: `npm run build` 성공
