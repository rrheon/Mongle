# 작업
답변 완료 시 
- 몽글 캐릭터를 선택하면 HistoryView에 기록되는게 다르게 도미
- 예) 파란색 몽글캐릭터 선택 -> HistoryView에서 초록색으로 기록되는 에러
- 답변 시 선택한 색상으로 기록될 것
- 답변 후 상대방에 질문을 볼 수 있는 화면도 마찬가지로 사용자가 해당 날짜에 답변할때선택한 캐릭터의 색상으로 적용할 것

재촉하기 시 
- [API Error] 404 NOT_FOUND: 대상 가족 구성원을(를) 찾을 수 없습니다.
- 그룹 내 같이 있음에도 이런 오류가 발생함 이를 해결할 것

마이페이지 접속 시 오류가 발생한는데 이를 해결할 것
1   0x18de71bbc WebKit::WebFramePolicyListenerProxy::ignore(WebKit::WasNavigationIntercepted)
2   0x18db3dd50 WebKit::NavigationState::NavigationClient::decidePolicyForNavigationAction(WebKit::WebPageProxy&, WTF::Ref<API::NavigationAction, WTF::RawPtrTraits<API::NavigationAction>, WTF::DefaultRefDerefTraits<API::NavigationAction>>&&, WTF::Ref<WebKit::WebFramePolicyListenerProxy, WTF::RawPtrTraits<WebKit::WebFramePolicyListenerProxy>, WTF::DefaultRefDerefTraits<WebKit::WebFramePolicyListenerProxy>>&&)::$_0::operator()(WKNavigationActionPolicy, WKWebpagePreferences*)
3   0x105ec7200 GADMRAIDEnvironmentScript
4   0x18db255c0 WebKit::NavigationState::NavigationClient::decidePolicyForNavigationAction(WebKit::WebPageProxy&, WTF::Ref<API::NavigationAction, WTF::RawPtrTraits<API::NavigationAction>, WTF::DefaultRefDerefTraits<API::NavigationAction>>&&, WTF::Ref<WebKit::WebFramePolicyListenerProxy, WTF::RawPtrTraits<WebKit::WebFramePolicyListenerProxy>, WTF::DefaultRefDerefTraits<WebKit::WebFramePolicyListenerProxy>>&&)
5   0x18dea9848 WebKit::WebPageProxy::decidePolicyForNavigationAction(WTF::Ref<WebKit::WebProcessProxy, WTF::RawPtrTraits<WebKit::WebProcessProxy>, WTF::DefaultRefDerefTraits<WebKit::WebProcessProxy>>&&, WebKit::WebFrameProxy&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&)
6   0x18dea7a34 WebKit::WebPageProxy::decidePolicyForNavigationActionAsync(IPC::Connection&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&)
7   0x18d9cbbf4 void IPC::handleMessageAsync<Messages::WebPageProxy::DecidePolicyForNavigationActionAsync, IPC::Connection, WebKit::WebPageProxy, WebKit::WebPageProxy, void (IPC::Connection&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&)>(IPC::Connection&, IPC::Decoder&, WebKit::WebPageProxy*, void (WebKit::WebPageProxy::*)(IPC::Connection&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&))
8   0x18d9c7728 WebKit::WebPageProxy::didReceiveMessage(IPC::Connection&, IPC::Decoder&)
9   0x18e49a0d8 IPC::MessageReceiverMap::dispatchMessage(IPC::Connection&, IPC::Decoder&)
10  0x18df1908c WebKit::WebProcessProxy::dispatchMessage(IPC::Connection&, IPC::Decoder&)
11  0x18d9dfc28 WebKit::WebProcessProxy::didReceiveMessage(IPC::Connection&, IPC::Decoder&)
12  0x18e47f72c IPC::Connection::dispatchMessage(WTF::UniqueRef<IPC::Decoder>)
13  0x18e47fac4 IPC::Connection::dispatchIncomingMessages()
14  0x199ad3758 WTF::RunLoop::performWork()
15  0x199ad4eb0 WTF::RunLoop::performWork(void*)
16  0x1804563a4 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__
17  0x1804562ec __CFRunLoopDoSource0
18  0x180455a78 __CFRunLoopDoSources0
19  0x180454c4c __CFRunLoopRun
20  0x18044fcec _CFRunLoopRunSpecificWithOptions
21  0x1926be9bc GSEventRunModal
22  0x18630f0d8 -[UIApplication _run]
23  0x186313300 UIApplicationMain
24  0x1d9e7d128 $s7SwiftUI17KitRendererCommon33_ACC2C5639A7D76F611E170E831FCA491LLys5NeverOyXlXpFAESpySpys4Int8VGSgGXEfU_
25  0x1d9e7ce70 $s7SwiftUI6runAppys5NeverOxAA0D0RzlF
26  0x1d9c0af34 $s7SwiftUI3AppPAAE4mainyyFZ
27  0x1050d7d3c $s6Mongle0A3AppV5$mainyyFZ
28  0x1050d7de8 __debug_main_executable_dylib_entry_point
29  0x1021213d0 28  dyld                                0x00000001021213d0 start_sim + 20
30  0x102394d54 29  ???                                 0x0000000102394d54 0x0 + 4332277076
1   0x18de71bbc WebKit::WebFramePolicyListenerProxy::ignore(WebKit::WasNavigationIntercepted)
2   0x18db3dd50 WebKit::NavigationState::NavigationClient::decidePolicyForNavigationAction(WebKit::WebPageProxy&, WTF::Ref<API::NavigationAction, WTF::RawPtrTraits<API::NavigationAction>, WTF::DefaultRefDerefTraits<API::NavigationAction>>&&, WTF::Ref<WebKit::WebFramePolicyListenerProxy, WTF::RawPtrTraits<WebKit::WebFramePolicyListenerProxy>, WTF::DefaultRefDerefTraits<WebKit::WebFramePolicyListenerProxy>>&&)::$_0::operator()(WKNavigationActionPolicy, WKWebpagePreferences*)
3   0x105ec7200 GADMRAIDEnvironmentScript
4   0x18db255c0 WebKit::NavigationState::NavigationClient::decidePolicyForNavigationAction(WebKit::WebPageProxy&, WTF::Ref<API::NavigationAction, WTF::RawPtrTraits<API::NavigationAction>, WTF::DefaultRefDerefTraits<API::NavigationAction>>&&, WTF::Ref<WebKit::WebFramePolicyListenerProxy, WTF::RawPtrTraits<WebKit::WebFramePolicyListenerProxy>, WTF::DefaultRefDerefTraits<WebKit::WebFramePolicyListenerProxy>>&&)
5   0x18dea9848 WebKit::WebPageProxy::decidePolicyForNavigationAction(WTF::Ref<WebKit::WebProcessProxy, WTF::RawPtrTraits<WebKit::WebProcessProxy>, WTF::DefaultRefDerefTraits<WebKit::WebProcessProxy>>&&, WebKit::WebFrameProxy&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&)
6   0x18dea7a34 WebKit::WebPageProxy::decidePolicyForNavigationActionAsync(IPC::Connection&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&)
7   0x18d9cbbf4 void IPC::handleMessageAsync<Messages::WebPageProxy::DecidePolicyForNavigationActionAsync, IPC::Connection, WebKit::WebPageProxy, WebKit::WebPageProxy, void (IPC::Connection&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&)>(IPC::Connection&, IPC::Decoder&, WebKit::WebPageProxy*, void (WebKit::WebPageProxy::*)(IPC::Connection&, WebKit::NavigationActionData&&, WTF::CompletionHandler<void (WebKit::PolicyDecision&&)>&&))
8   0x18d9c7728 WebKit::WebPageProxy::didReceiveMessage(IPC::Connection&, IPC::Decoder&)
9   0x18e49a0d8 IPC::MessageReceiverMap::dispatchMessage(IPC::Connection&, IPC::Decoder&)
10  0x18df1908c WebKit::WebProcessProxy::dispatchMessage(IPC::Connection&, IPC::Decoder&)
11  0x18d9dfc28 WebKit::WebProcessProxy::didReceiveMessage(IPC::Connection&, IPC::Decoder&)
12  0x18e47f72c IPC::Connection::dispatchMessage(WTF::UniqueRef<IPC::Decoder>)
13  0x18e47fac4 IPC::Connection::dispatchIncomingMessages()
14  0x199ad3758 WTF::RunLoop::performWork()
15  0x199ad4eb0 WTF::RunLoop::performWork(void*)
16  0x1804563a4 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__
17  0x1804562ec __CFRunLoopDoSource0
18  0x180455a78 __CFRunLoopDoSources0
19  0x180454c4c __CFRunLoopRun
20  0x18044fcec _CFRunLoopRunSpecificWithOptions
21  0x1926be9bc GSEventRunModal
22  0x18630f0d8 -[UIApplication _run]
23  0x186313300 UIApplicationMain
24  0x1d9e7d128 $s7SwiftUI17KitRendererCommon33_ACC2C5639A7D76F611E170E831FCA491LLys5NeverOyXlXpFAESpySpys4Int8VGSgGXEfU_
25  0x1d9e7ce70 $s7SwiftUI6runAppys5NeverOxAA0D0RzlF
26  0x1d9c0af34 $s7SwiftUI3AppPAAE4mainyyFZ
27  0x1050d7d3c $s6Mongle0A3AppV5$mainyyFZ
28  0x1050d7de8 __debug_main_executable_dylib_entry_point
29  0x1021213d0 28  dyld                                0x00000001021213d0 start_sim + 20
30  0x102394d54 29  ???                                 0x0000000102394d54 0x0 + 4332277076





---
## 참고사항

- 해당 파일은 수정 및 추가하지 말것
- 결과를 보고할 것이 있다면 파일을 새로 생성할 것
--- 
## 작업위치

서버프로젝트 경로
- /Users/yong/Desktop/FamTreeServer

iOS 프로젝트 경로
- /Users/yong/Desktop/FamTree

안드로이드 프로젝트 경로
- /Users/yong/Mongle-Android

디자인 시스템 경로
- /Users/yong/Desktop/FamTree/MongleUI.pen

작업 및 이슈 보고서 경로
- /Users/yong/Desktop/FamTree/Report
- 작업 후의 내용이나 이슈와 어떻게 해결했는지 작성할 것
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
