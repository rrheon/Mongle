# 작업

## 위치
- 디자인: /Users/yong/Desktop/FamTree/MongleUI
- iOS: /Users/yong/Desktop/FamTree
- Android: /Users/yong/Mongle-Android
- 서버: /Users/yong/Desktop/MongleServer

## 구글 ad정보

iOS
앱ID : ca-app-pub-4718464707406824~3555712259
- 배너: ca-app-pub-4718464707406824/5359748516
- 보상형: ca-app-pub-4718464707406824/2869316545

Android
앱ID: ca-app-pub-4718464707406824~8995741193
- 배너: ca-app-pub-4718464707406824/2974225929
- 보상형: ca-app-pub-4718464707406824/9365243021

---

~~iOS에서 초대코드 입력화면에�� 텍스트필드와 그룹만들기에서 텍스트필드의 플레이스 홀더 텍스트의 색상은 거의 안보이는데 이걸 수정해줘~~ ✅

~~아래의 오류를 수정할 것~~ ✅
- ifLet mongleCardEdit: `@Dependency(\.dismiss)` 적용, 부모에서 state nil 제거
- forEach writeQuestion(.setAppError): MongleErrorToastModifier에 Task.isCancelled 체크 추가

~~토스트팝업이 다국어 지원을 안하고 한글로만 ��어있는데 일본어, 영어 대응을 할 것~~ ���
- HeartInfoPopupView, PeerAnswerView, QuestionDetailFeature, GroupSelectFeature, WriteQuestionView, MainTab+Reducer 다국어 처리 완료
