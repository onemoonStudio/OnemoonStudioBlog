# Escaping Closure

자주 사용하고 있지만 정확한 개념을 설명하기 어렵다는 생각이 들어서 이번 포스팅에서 한번 정리해보고자 합니다. 처음 Swift를 공부하던 시절에 제일 헷갈렸던 부분이었던 것 같습니다. escaping closure를 이해하기 위해서는 몇가지 개념을 미리 알고 있는 것이 편합니다. 비동기 코드를 쓰는 이유, scope의 개념, capturing values 를 먼저 설명한 뒤 escaping closure 그리고 이를 통해 생길 수 있는 strong reference cycle에 대해서 설명하도록 하겠습니다. 잘못된 부분이 있다면 댓글로 남겨주시면 감사하겠습니다!



## 비동기 코드를 쓰는 이유

이미 다른 블로그를 통해서 동기와 비동기에 대해서 많이 설명을 해놨기 때문에 저는 직접적으로 iOS에서 활용하는 방식을 예를 들어 설명하겠습니다. 

escaping closure 가 가장 많이 활용되는 곳은 네트워크를 통해서 데이터를 받아올 때 입니다. 기본적으로 우리가 함수를 작성하면 해당 함수는 동기적으로 작동합니다. 반면에 네트워크 API는 어떤 형식으로든 비동기적으로 작성을 할 수 있도록 유도하는 것을 많이 확인할 수 있습니다. 이유는 네트워크를 받아오는 시간동안 사용자가 아무런 동작을 못하는 freezing 현상을 방지하기 위함입니다. 

```swift
func testEscaping(_ esClosure: @escaping (Data?) -> Void) {
  let urlRequest = URLRequest(url: URL(string: "hello world")!)

  session.dataTask(with: urlRequest) 
  { data, response, error in
		print("world")
		print("update UI or Alert")
	}.resume()
  
  print("hello")
}	
```

해당 코드를 실행해보면 session.dataTask ( Network )는 비동기 방식이기 때문에 실행이후, 응답을 기다리지 않고 hello가 찍힐 것입니다. 그 이후 네트워크를 통해 응답을 받게되면 world, update UI or Alert 가 찍히게 되겠죠. 이때 hello 가 찍히고 나서 응답이 올때까지 기다리는 동안에도 사용자는 앱을 동작시킬 수 있다는 것이 비동기의 큰 장점입니다. 이를 통해서 사용자의 경험을 높힐 수 있는 것입니다.

요청 > 사용자 행동 ( 사용자 경험 Good ) > 응답 > 내부 동작

반대로 네트워크가 동기적으로 작동한다면 어떻게 될까요? 요청을 하고 응답을 하는 시간이 2초가 걸린다고 할때, 2초동안 사용자가 어떠한 동작도 하지 못한다면 사용자의 경험을 해칠 수 있습니다.

요청 > 기다림 ( freezing , 사용자 경험 Bad ) > 응답 > 내부동작 

## Scope

```swift
func someFunc() -> Int {
	let hello = "world"
  return 0
}

someFunc()

```

문서에 있는 예시를 조금 변형해서 Scope에 대한 개념을 설명해드리겠습니다. someFunc 라는 함수가 있습니다. 그리고 내부에 hello 라는 변수가 있습니다. 일반적으로 함수의 스코프라 함은 함수의 바디 즉 { 부터 } 까지를 의미합니다. 그리고 리턴이 되면 해당 스코프 내부에 있는 변수들은 소멸됩니다. 그리고 함수가 실행될때 새로운 hello 가 다시 생성되어 작업이 진행됩니다. 

리턴이 될때 내부에서 사용한 변수들 ( 지역변수 )가 사라진다고 이해하면 됩니다. 하지만 어떻게 생각하면 예외의 경우가 있는데 그 경우가 아래에서 설명하는 capturing values 입니다.

## capturing values





## escaping closures

먼저 문서를 한번 살펴보겠습니다. 정의는 이렇게 나와있습니다.



**A closure is said to *escape* a function when the closure is passed as an argument to the function, but is called after the function returns.** 



인자로 전달받은 함수 중 함수의 리턴 이후에 실행할 수 있는 함수가 escaping closure 입니다. 복잡해 보이지만 하나하나씩 풀어보면 그렇게 어렵지 않습니다. 쉽게 말해 함수의 리턴 이후 실행할 수 있는 함수이다. 라고 이해하시면 될 것 같습니다.





여기서 escape의 의미를 생각해봐야합니다. 어디에서 탈출하는 걸까요? 작성한 함수의 바디(스코프)에서 탈출하는 것입니다. 

```swift
func testEscaping(_ esClosure: @escaping (Int) -> Void)
{ // Start A
let urlRequest = URLRequest(url: URL(string: "hello world")!)

let dataTask = session.dataTask(with: urlRequest)
{ data, response, error in // Start B
	print("world")
	esClosure(3)
}.resume() // End B

print("hello")
} // End A
```

여기서 Start A ~ End A 까지 A scope라고 하겠습니다. 또한 Start B ~ End B 까지 B scope 라고 하겠습니다. A scope는 함수가 실행될 때 생성되며 함수가 리턴되면 사라집니다. 또한 일반적으로 내부의 urlRequest 라는 지역변수 또한 마찬가지로 A scope와 생명주기가 동일합니다. ( capturing values 는 얘기가 다릅니다. 꼭 읽어보세요 ! )

하지만 B scope의 경우는 의도가 다릅니다. A Scope 내부에서 정의했지만 네트워크 부분이기 때문에 리턴이 된 이후에 실행되어야 합니다 ( A scope가 사라지는 시점 ). 이렇게 리턴이 된 이후에도 B scope를 실행할 수 있도록 하기 위해서 @escaping 을 붙이는 것입니다. 즉 @escaping 을 붙임으로써 A scope를 벗어난 새로운 스코프가 생기는 것입니다.



## Strong reference cycle from escaping closure







## reference

[Capturing Values](https://docs.swift.org/swift-book/LanguageGuide/Closures.html#ID103)

[Escaping Closure](https://docs.swift.org/swift-book/LanguageGuide/Closures.html#ID546)

[Strong Reference Cycle](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html#ID56)

