# ResponderChain

단순히 Responder Chain을 설명하기 보다는 어떤 요소들이 결합되어서 Responder Chain 이 어떻게 그리고 왜 사용되었는지를 설명하고자 한다. 또한 먼저 Article을 읽어보기 보다는 각 요소들의 문서를 먼저 읽어보며 정리하고 마지막에는 Article 을 종합하면서 마무리 할 예정이다.

- UIResponder
- UIEvent
- UIControl
- [ Article ] Using Responders and the Responder Chain to Handle Events



## UIResponder

이벤트에 반응하고 다룰수 있도록 하는 추상 인터페이스이다.

UIResponder 의 인스턴스를 **Responder Object**라고 부른다. 또한 이는 UIKit app 에서 이벤트를 다루는 근간으로 이루어져 있다. 또한 UIApplication, UIViewController, all UIView 와 같은 여러 핵심 객체들 또한 responder이다. **이벤트**가 발생하면 UIKit은 responder object로 이벤트를 전달하게 된다.

특정한 이벤트의 경우 다루기 위해서는 상응하는 메서드를 override 해야 한다. 예를 들어서 터치를 다루기 위해서는 touchesBegan , touchesMoved, touchesEnded, touchesCancelled 를 override 해야 한다.

 이벤트를 다루는 것 말고도, **Responder 는 다루지 못한 이벤트를 앱의 다른 파트로 넘길 수 있어야 한다.** 들어온 이벤트를 처리하지 않는다면 responder chain을 따라서 다음으로 넘긴다. UIKit은 responder chain 을 동적으로 관리하는데, 사전에 정의된 룰에 따라서 어떤 object가 next가 되어서 이벤트를 받을 지 결정한다. 예를 들어서 view는 superview로, root view는 viewController 로 진행된다.

기본적으로 Responder 는 UIEvent를 처리하지만 input view를 통해서 custom input을 받을 수도 있다. 특히 inputview의 명확한 예라고 할 수 있다. 예를 들어서 UITextfield , UITextView를 유저가 누르는 경우 first Responder가 되면서 inputView( 시스템 키보드 )를 보여준다. 이와 비슷하게 customview를 직접 만들어 responder가 active 되었을때 보여줄 수도 있다.

---

여기서 이미 Responder Chain에 대부분을 설명해준 것을 확인할 수 있다. 우리가 사용하는 대부분의 UI요소들은 ResponderObeject이며 다루지 못한 이벤트를 다음으로 넘겨주기 위해서 사전에 정의된 Responder Chain 을 따라 이벤트를 전달한다.

이때 UIResponder의 property 중에서 [next](https://developer.apple.com/documentation/uikit/uiresponder/1621099-next)를 확인할 수 있다. 해당 property의 정의를 확인해보면 **Returns the next responder in the responder chain, or `nil` if there is no next responder.** 즉 ResponderChain의 요소 중 다음 Responder를 리턴하는 역할이다. 결국 next를 통해서 연결된 Responder 들이 Responder Chain을 이룬다는 것을 알 수 있다.



> [UIResponder Document](https://developer.apple.com/documentation/uikit/uiresponder)
>
> [UIResponder - next](https://developer.apple.com/documentation/uikit/uiresponder/1621099-next)



## UIEvent

앱에서 하나의 유저 인터렉션을 설명하는 객체

앱은 touch, motion, remote-control 과 같은 여러 타입의 이벤트를 받는다. ( 각 이벤트에 대한 설명 ). 이러한 이벤트는 type 와 subtype의 프로퍼티를 통해서 타입을 결정할 수 있다. 

터치 이벤트는 이벤트와 관련된 터치들을 갖고 있다. 터치 이벤트는 하나 혹은 이상의 터치를 갖고 있으며, 각 터치는 UITouch Object이다. 터치 이벤트가 발생하면, 시스템은 적절한 repsonder를 찾아서 적절한 method를 실행시킨다.

멀티터치 단계에서는 UIKit이 동일한 UIEvent 객체를 터치데이터를 업데이트 하면서 재사용한다. 해당 객체를 갖고있어서는 안된다. 만약에 해당 객체를 갖고 있어야 한다면 값을 복사해서 갖고있어야 한다. 

---

우리가 생각하는 터치 이벤트 혹은 롱프레스 등이 UIEvent 형태로 UIKit이 전달하는 것이다. 

> [UIEvent Document](https://developer.apple.com/documentation/uikit/uievent)



## UIControl

유저 인터렉션을 통한 특별한 액션과 의도를 갖춘 컨트롤을 관리하는 클래스이다.



















