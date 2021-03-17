# ResponderChain

단순히 Responder Chain을 설명하기 보다는 어떤 요소들이 결합되어서 Responder Chain 이 어떻게 그리고 왜 사용되었는지를 설명하고자 한다. 또한 먼저 Article을 읽어보기 보다는 각 요소들의 문서를 먼저 읽어보며 정리하고 마지막에는 Article 을 종합하면서 마무리 할 예정이다.

대부분 문서의 내용을 해석했으며 핵심내용을 제외한 일부는 생략을 하였다. 따라서 이해가 잘 되지 않는다면 직접 가서 읽는 것을 추천한다.

- UIResponder
- UIEvent
- UIControl
- [ Article ] Using Responders and the Responder Chain to Handle Events
- Summary



## UIResponder

> 이벤트에 반응하고 다룰수 있도록 하는 추상 인터페이스이다.

UIResponder 의 인스턴스를 **Responder Object**라고 부른다. 또한 이는 UIKit app 에서 이벤트를 다루는 근간으로 이루어져 있다. 또한 UIApplication, UIViewController, all UIView 와 같은 여러 핵심 객체들 또한 responder이다. **이벤트**가 발생하면 UIKit은 responder object로 이벤트를 전달하게 된다.

특정한 이벤트의 경우 다루기 위해서는 상응하는 메서드를 override 해야 한다. 예를 들어서 터치를 다루기 위해서는 touchesBegan , touchesMoved, touchesEnded, touchesCancelled 를 override 해야 한다.

 이벤트를 다루는 것 말고도, **Responder 는 다루지 못한 이벤트를 앱의 다른 파트로 넘길 수 있어야 한다.** 들어온 이벤트를 처리하지 않는다면 responder chain을 따라서 다음으로 넘긴다. UIKit은 responder chain 을 동적으로 관리하는데, 사전에 정의된 룰에 따라서 어떤 object가 next가 되어서 이벤트를 받을 지 결정한다. 예를 들어서 view는 superview로, root view는 viewController 로 진행된다.

기본적으로 Responder 는 UIEvent를 처리하지만 input view를 통해서 custom input을 받을 수도 있다. 특히 inputview의 명확한 예라고 할 수 있다. 예를 들어서 UITextfield , UITextView를 유저가 누르는 경우 first Responder가 되면서 inputView( 시스템 키보드 )를 보여준다. 이와 비슷하게 customview를 직접 만들어 responder가 active 되었을때 보여줄 수도 있다.

---

여기서 이미 Responder Chain에 대부분을 설명해준 것을 확인할 수 있다. 우리가 사용하는 대부분의 UI요소들은 ResponderObeject이며 다루지 못한 이벤트를 다음으로 넘겨주기 위해서 사전에 정의된 Responder Chain 을 따라 이벤트를 전달한다.

이때 UIResponder의 property 중에서 [next](https://developer.apple.com/documentation/uikit/uiresponder/1621099-next)를 살펴보자. 해당 property의 정의를 확인해보면 **Returns the next responder in the responder chain, or `nil` if there is no next responder.** 즉 ResponderChain의 요소 중 다음 Responder를 리턴하는 역할이다. 결국 next를 통해서 연결된 Responder 들이 Responder Chain을 이룬다는 것을 알 수 있다.



## UIEvent

> 앱에서 하나의 유저 인터렉션을 설명하는 객체

앱은 touch, motion, remote-control 과 같은 여러 타입의 이벤트를 받는다. ( 각 이벤트에 대한 설명 ). 이러한 이벤트는 type 와 subtype의 프로퍼티를 통해서 타입을 결정할 수 있다. 

터치 이벤트는 이벤트와 관련된 터치들을 갖고 있다. 터치 이벤트는 하나 혹은 이상의 터치를 갖고 있으며, 각 터치는 UITouch Object이다. 터치 이벤트가 발생하면, 시스템은 적절한 repsonder를 찾아서 적절한 method를 실행시킨다.

멀티터치 단계에서는 UIKit이 동일한 UIEvent 객체를 터치데이터를 업데이트 하면서 재사용한다. 해당 객체를 갖고있어서는 안된다. 만약에 해당 객체를 갖고 있어야 한다면 값을 복사해서 갖고있어야 한다. 

---

우리가 생각하는 터치 이벤트 혹은 롱프레스 등이 UIEvent 형태로 UIKit을 통해서 전달이 되는 것이다. 



## UIControl

> 유저 인터렉션을 통한 특별한 액션과 의도를 갖춘 컨트롤을 관리하는 클래스이다.

네비게이션을 편하게 한다던지, 유저의 의도를 돕는다던지 하는 기능을 갖추고 있으며 버튼, 슬라이더 등을 포함하고 있다. 이때 Control은 **target-action mechanism**을 이용하여 앱과 상호작용을 한다.

UIControl을 직접 생성하지 말고 만약 커스텀 이벤트 컨트롤이 필요한 경우에는 이를 서브클래싱 하는것이 좋다. 확장이 필요하다면, 이미 존재하는 control class 를 상속받도록 하자. 

control's state 를 통해서 contorl의 외관과 유저 인터렉션을 지원하는 것이 바뀐다. [UIControl.State](https://developer.apple.com/documentation/uikit/uicontrol/state)에 따라서 Control은 여러 상태중 하나의 상태를 가진다. 또한 앱의 필요에 따라서 상태를 변경시킬 수 도 있다. 

#### The Target-Actio Mechanism

타겟-액션 메커니즘은 앱을 컨트롤하기 위한 코드를 단순화 시켜준다. 터치 이벤트를 쫓아다니면서 코드를 작성하는 대신에, contol-specific events 에 대해서 action method만 정리하면 된다. 

action method를 control에 추가하기 위해서는 action method 그리고 addTarget(_:action:for:) method를 정의한 객체를 명시해야한다. target object 는 어떤한 객체도 될 수 있다, 하지만 전형적으로 control을 포함하는 viewControlle's 의 root view가 된다. ( 보통 ViewController가 target object 가 되는 것으로 생각하고 있었는데, 이 부분은 조금 이해가 안되네요 ㅠㅠ 이유를 댓글 달아주시면 감사하겠습니다. ) 만약 target Object 를 nil 로 설정한다면, control은 responder chain 을 따라서 action method 를 정의한 객체를 찾아 나선다.

```swift
@IBAction func doSomething()
@IBAction func doSomething(sender: UIButton)
@IBAction func doSomething(sender: UIButton, forEvent event: UIEvent)		
```

action method는 전형적으로 위의 3개의 형식중 하나를 따른다. 이때 sender parameter는 action method를 호출한 contol이고, event parameter는 control-related 를 발생시키는 이벤트가 된다.

시스템은 컨트롤이 유저와 특정한 방식으로 인터렉션을 할 때 action method를 실행시킨다. [UIControl.Event](https://developer.apple.com/documentation/uikit/uicontrol/event)에 control이 발생시킬 수 있는 특정한 방식의 인터렉션을 정의해놨으며, 이러한 인터렉션은 컨트롤의 특정한 터치이벤트와 연관이 되어 있다. control을 설정할 때, 반드시 어떤 이벤트가 트리거 되어 method를 실행시키는지 명시해야 한다. 예를 들어서 버튼에는 touchDown, touchUpInside 가 사용 될 것이며, 슬라이더에서는 valueChanged 라는 이벤트를 사용할 수 있을 것이다.

위에서 할만 control-specific event가 발생했을 때, control은 연관된 action method를 즉시 호출한다. 현재 UIApplication은 만약 필요하다면 responder chain을 따라서라도, 메세지를 다룰 수 있는 적절한 객체를 찾고 이벤트를 전달한다. 

---

UIControl은 결국 특정한 유저의 인터렉션을 감싼 UIView의 서브클래스이다. 흐름을 이해하기 위해서는 UIContol 자체보다 Target-Action이 뭔지, 이벤트가 어떻게 전달이 되어서 메서드가 실행되는지를 중점적으로 확인하도록 하자.

이 외에도 Interface Builder Attributes, Internationalization, Accessibility, Subclassing 에 대한 설명이 있지만, responder chain을 이해하기 위한 내용을 중점적으로 정리하는 것이니 생략하였다. 자세한 내용을 알고 싶다면 하단의 reference를 통해서 문서를 참고하도록 하자. 



## [ Article ] Using Responders and the Responder Chain to Handle Events

> 앱을 통해서 전달되는 이벤트를 어떻게 다루는지 배워보자

#### Overview

앱은 responder object(이하 리스폰더)를 통해서 이벤트를 받고 처리한다. 리스폰더는 UIResponder class의 어떠한 인스턴스도 될 수 있으며, UIView, UIViewController, UIApplication 등이 그 예시이다. **리스폰더는 raw event data를 받게되면 반드시 이를 처리하거나 다른 리스폰더로 전달을 해야 한다.** 이벤트를 받으면 UIKit은 자동으로 가장 적절한 리스폰더를 찾아서 전달하는데 이를 **first responder** 라고 한다.

동적으로 변경되는 app's responder chain을 따라서, 다뤄지지 않은 이벤트는 활성화된 responder chain에 따라서 리스폰더에서 리스폰더로 전달이 된다. 하단 사진을 통해서 label, textfield, button 그리고 두개의 background views로 구성된 앱의 리스폰더들을 확인할 수 있다. 화살표를 따라서 이벤트가 리스폰더에서 next(리스폰더)로 responder chain을 통해서 어떻게 전달되는지 확인할 수 있다.

![f17df5bc-d80b-4e17-81cf-4277b1e0f6e4](https://docs-assets.developer.apple.com/published/7c21d852b9/f17df5bc-d80b-4e17-81cf-4277b1e0f6e4.png)

만약 textfield 가 이벤트를 처리하지 않는다면, UIKit 은 이벤트를 textfield 의 부모인 UIView로 전달하고, 이후에 window의 root view에 이르게 된다. root view 부터는 responder chain이 이벤트를 window로 전달하기 전, UIViewController로 전환이 된다. 만약, window 마저 해당 이벤트를 처리하지 못하면 이벤트는 UIApplication으로 전달이 되며, 만약 appDelegate가 UIResponder의 인스턴스라면 여기까지 전달이 될 것이다.

#### Determining an Event's First Responder

UIKit은 이벤트 유형에 따라 이벤트의 first responder를 지정하는데, 이벤트의 타입과 규칙은 아래와 같다.

| Event type            | First responder                           |
| --------------------- | :---------------------------------------- |
| Touch events          | The view in which the touch occurred.     |
| Press events          | The object that has focus.                |
| Shake-motion events   | The object that you (or UIKit) designate. |
| Remote-control events | The object that you (or UIKit) designate. |
| Editing menu messages | The object that you (or UIKit) designate. |

**Note** accelerometers, gyroscropes, and magnetometer 같은 모션 이벤트는 responder chain을 따르지 않는다. 대신에 Core Motion가 특정한 객체로 이벤트를 전달하게 된다. 자세한 내용은 [Core Motion FrameWork](https://developer.apple.com/documentation/coremotion?language=occ) 를 확인하자.  

컨트롤은 연관된 target object와 action message로 대화를 한다. 유저가 컨트롤과 상호작용을 하게 되면, 컨트롤은 action message를 target object로 전달을 하게 된다. **Action message 는 이벤트가 아니지만, responder chain의 이점을 이용할 수 있다.** 만약 target object가 nil 이라면, UIKit은 해당 object부터 시작해 적절한 action method를 구현한 객체를 찾을 때 까지 responder chain을 순회하게 된다. 예를 들어, UIKit은 editing menu의 행동이 발생하면 cut(_:), copy(_:), paste(_:) 와 같은 method를 구현한 객체를 찾기 위해서 responder chain을 순회하게 될 것이다.

**Gesture recognizer는 터치와 누르는 이벤트를 뷰보다 먼저 받는다.** 만약 view's gesture recognizer 가 연속되는 터치 이벤트를 받지 못한다면, UIKit은 이를 뷰로 전달한다. 만약 뷰가 touch를 처리하지 못한다면, UIKit은 responder chain을 따라서 터치 이벤트를 전달한다. 조금 더 자세한 내용을 알고 싶다면 [Handling UIKit Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_uikit_gestures) 를 살펴보자.

#### Determining Which Responder Contained a Touch Event

UIKit은 touch event 가 어디에서 발생했는지 확인하기 위해서 view-based hit-testing 을 사용한다. 특히 UIKit은 touch location과 view hierarchy 에 있는 뷰 객체의 bounds 를 비교한다. **UIView의 hitTest(_:with:) method는 view hierarchy를 순회하며, 특정 터치를 포함하는 가장 깊은 subview를 찾으며, 해당 view는 터치 이벤트의 first responder 가 된다.** 

**Note** 만약 터치 이벤트가 view's bounds 의 영역을 벗어난다면, hitTest(_:with:)은 해당 view 그리고 해당 view 의 모든 subview들을 무시한다. 그 결과로, view's clipsToBounds가 false 인 경우, view's bounds 의 바깥에 있는 subviews들은 터치를 포함하고 있더라도 리턴이 되지 않는다. hit-testing에 대해서 더 알아보고 싶다면 [hitTest( _:with:)](https://developer.apple.com/documentation/uikit/uiview/1622469-hittest) 의 discussion을 참고하자

터치 이벤트가 발생하면, UIKit은 UITouch 객체를 만들어 view와 연결시킨다. 터치의 위치가 바뀌거나 다른 parameter가 변경 된다면, UIKit은 동일한 UITouch 객체를 새로운 정보로 업데이트 한다. 오로지 view만 변경되지 않는다. ( 만약 터치의 영역이 뷰를 벗어나더라도 view는 변경되지 않는다. ) 터치가 끝나면, UIKit은 UITouch 객체를 release 한다.

#### Altering the Responder Chain

리스폰더의 next property를 override 해서 responder chain을 변경할 수 있다. 이를 할 때, next responder는 리턴하는 값이 된다. 

많은 UIKit classes 들이 next property를 override 해서 특정한 객체를 리턴하고 있다. 

UIView를 생각해보자. 만약 뷰가 **ViewController의 root view 라면, next property는 ViewController**가 된다. **그렇지 않으면 ( root view 가 아니라면 ) next responder는 superview**가 된다.

UIViewController를 생각해보자. 만약 **ViewController's view 가 window 의 root view 라면, next responder는 window**가 된다. 혹은 만약 ViewController가 **다른 ViewController에 의해서 띄워졌다면, next responder는 presenting ViewController**가 된다.

UIWindow를 생각해보자. **next responder는 UIApplication**이다.

UIApplication을 생각해보자. delegate가 UIResponder의 인스턴스이고, View, ViewController, app 이 아닌 경우에만  next responder가 app delegate가 된다. 



// 요약 및 Summary 남음



## Reference

[UIResponder Document](https://developer.apple.com/documentation/uikit/uiresponder)

[UIResponder - next](https://developer.apple.com/documentation/uikit/uiresponder/1621099-next)

[UIEvent Document](https://developer.apple.com/documentation/uikit/uievent)

[UIControl Document](https://developer.apple.com/documentation/uikit/uicontrol)

[UIControl - UIControl.State](https://developer.apple.com/documentation/uikit/uicontrol/state)

[UIControl - UIControl.Event](https://developer.apple.com/documentation/uikit/uicontrol/event)

[[ Article ] Using Responders and the Responder Chain to Handle Events](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/using_responders_and_the_responder_chain_to_handle_events)

[Article - Core Motion FrameWork](https://developer.apple.com/documentation/coremotion?language=occ)

[Article - Handling UIKit Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_uikit_gestures)

[Article - hitTest(_:with:)](https://developer.apple.com/documentation/uikit/uiview/1622469-hittest)





































