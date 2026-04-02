# 작업

링크를 타고 들어가면 아래와 같은 에러가 발생해
Received port for identifier response: <(null)> with error:Error Domain=RBSServiceErrorDomain Code=1 "Client not entitled" UserInfo={RBSEntitlement=com.apple.runningboard.process-state, NSLocalizedFailureReason=Client not entitled, RBSPermanent=false}

로그아웃 시 아래와 같은 에러가 발생해 
An "ifLet" at "MongleFeatures/Root+Reducer.swift:488" received a child action when child state was "nil".

  Action:
    RootFeature.Action.mainTab(
      .profile(.onAppear)
    )

This is generally considered an application logic error, and can happen for a few reasons:

A parent reducer set child state to "nil" before this reducer ran. This reducer must run before any other reducer sets child state to "nil". This ensures that child reducers can handle their actions while their state is still available.

An in-flight effect emitted this action when child state was "nil". While it may be perfectly reasonable to ignore this action, consider canceling the associated effect before child state becomes "nil", especially if it is a long-living effect.

This action was sent to the store while state was "nil". Make sure that actions for this reducer can only be sent from a store when state is non-"nil". In SwiftUI applications, use "IfLetStore".


그룹 나가기 시 이런 에러가 발생해
<decode: bad range for [%{public}s] got [offs:350 len:1369 within:0]> 

몽글 초대 페이지에 나뭇잎말고 몽글로고를 넣어줘
## 위치
디자인: /Users/yong/Desktop/FamTree/MongleUI
iOS: /Users/yong/Desktop/FamTree
Andriod: /Users/yong/Mongle-Android 
서버: /Users/yong/Desktop/MongleServer
---
## 구글 ad정보

iOS
앱ID : ca-app-pub-4718464707406824~3555712259
- 배너
ca-app-pub-4718464707406824/5359748516
- 보상형
ca-app-pub-4718464707406824/2869316545

Andriod
앱ID: ca-app-pub-4718464707406824~8995741193
- 배너
 ca-app-pub-4718464707406824/2974225929

- 보상형
 ca-app-pub-4718464707406824/9365243021
