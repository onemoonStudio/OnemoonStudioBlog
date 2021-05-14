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

Scope는 크게 global scope, local scope 2가지로 나누어집니다. global scope에 대한 자세한 내용은 [여기](https://andybargh.com/lifetime-scope-and-namespaces-in-swift/#Scope)에서 확인하는 것을 추천합니다. 예제를 통해서 local scope인 함수의 스코프에 대해서 설명을 드리겠습니다.

```swift
func someFunc() -> Int {
	let hello = "world"
  return 0
}

someFunc()

```

 someFunc 라는 함수가 있습니다. 그리고 내부에 hello 라는 변수가 있습니다. 일반적으로 함수의 스코프라 함은 함수의 바디 즉 { 부터 } 까지를 의미합니다. 해당 스코프는 함수가 실행될 때 활성화되며, 리턴이 되면 해당 스코프 내부에 있는 변수들은 소멸됩니다. 함수의 바깥에서는 해당 변수를 접근할 수 없으며, 따라서 리턴이 되면( 함수의 실행이 끝나면 ) 가지고 있을 필요가 없기 때문입니다. 이런 메커니즘을 가진 것이 local scope이며, 내부의 변수를 local variable 이라고 합니다.

하지만 local variable이 이런 local scope를 무시하고 <u>계속 참조되는 것 처럼 보이는</u> 예외의 경우가 있는데, 이 경우는 아래에서 설명하는 capturing values 를 통해서 이루어집니다.

## capturing values

문서를 먼저 확인해보겠습니다. 



**A closure can *capture* constants and variables from the surrounding context in which it’s defined. The closure can then refer to and modify the values of those constants and variables from within its body, even if the original scope that defined the constants and variables no longer exists.**



요약하자면 클로저는 주변에 있는 변수를 참조할 수 있으며, original scope 를 무시한다고 합니다. 즉, 기존의 스코프와 관계없이 클로저만의 변수를 갖고 있다고 생각하면 됩니다. 문서의 예제를 보며 설명드리겠습니다.

```swift
func makeIncrementer(forIncrement amount: Int) -> () -> Int {
    var runningTotal = 0
  
    func incrementer() -> Int {
        runningTotal += amount
        return runningTotal
    }
  
    return incrementer
}

// ** 실행 ** 
let incrementByTen = makeIncrementer(forIncrement: 10)
incrementByTen()
// returns a value of 10
incrementByTen()
// returns a value of 20

let incrementBySeven = makeIncrementer(forIncrement: 7)
incrementBySeven()
// returns a value of 7

incrementByTen()
// returns a value of 30
```

makIncrementer 함수 내부에 incrementer 함수만 살펴보면 runningTotal 과 amount 변수는 사실상 바깥에서 선언한 변수입니다. incrementer 만 본다면 에러가 나지만 runningTotal과 amount 를 `capture` 했기 때문에 내부에서 사용이 가능합니다. 

또한 두번째로 살펴볼 것은 아래 실행 부분입니다. 위에서 클로저만의 변수를 갖고있다고 설명을 드렸듯이 incrementByTen, incrementBySeven 의 runningTotal 은 공유가 되지 않습니다. 각각 runningTotal 을 참조하는 변수를 가지고 있는 것이죠. 따라서  incrementBySeven() 을 실행시킨 뒤 incrementByTen() 을 실행시키더라도 각각의 플로우를 따르는 것을 확인할 수 있습니다. 

하지만 변수가 공유되는 경우 또한 존재합니다. 아래의 예제를 살펴보겠습니다.

```swift
class ClosureTestManager {   
    var resultValue = 0
    
    func add(_ amount: Int) -> () -> Int {
        return {
            self.resultValue += amount
            return self.resultValue
        }
    }
}

// ** 실행 **
let ma = ClosureTestManager()
let addTen = ma.add(10)
let addThree = ma.add(3)

addTen()
// returns a value of 10
addThree()
// returns a value of 13
addTen()
// returns a value of 23

```

상단의 예제는 캡쳐된 값들이 value type 이지만, 하단의 예제처럼 reference type을 캡쳐한 경우에는 공유가 됩니다. 결과에서 보이다시피 addThree() 를 실행시킨 경우 0 + 3 이 아닌 기존에 더해진 10 + 3 이 되어 13 이 리턴되는 것을 확인할 수 있습니다. 따라서 클로저에서 값을 사용하는 경우에는 어떤 타입의 값을 캡쳐하는지 유의해서 작성을 해야 한다는 것을 알아두시길 바랍니다.

## escaping closures

먼저 문서를 한번 살펴보겠습니다. 정의는 이렇게 나와있습니다.

**A closure is said to *escape* a function when the closure is passed as an argument to the function, but is called after the function returns.** 

인자로 전달받은 함수 중 함수의 리턴 이후에 실행할 수 있는 함수가 escaping closure 이다. 쉽게 말해 함수의 리턴 이후 실행할 수 있는 함수이다. 라고 이해하시면 될 것 같습니다. 계속해서 문서를 보겠습니다.

One way that a closure can escape is by being stored in a variable that’s defined outside the function. As an example, many functions that start an asynchronous operation take a closure argument as a completion handler. **The function returns after it starts the operation, but the closure isn’t called until the operation is completed—the closure needs to escape, to be called later**

바깥의 변수에 의해서 클로저가 저장되는 경우에 closure는 escape를 할 수 있다고 하네요. 대표적으로 사용하는 예시로는 비동기 작업을 하는 경우 completion handler로 escaping closure 를 사용하는 것을 확인할 수 있습니다. 작업이 시작되면 함수가 리턴되지만 클로저는 작업이 끝날 때 까지 호출되지 않습니다. 그리고 이 클로저를 나중에 호출하기 위해서 escape가 필요합니다.

여기서 escape의 의미를 생각해봐야합니다. 어디에서 탈출하는 걸까요? 함수의 스코프에서 탈출한다고 이해하면 좋을 것 같습니다. 함수가 리턴이 되면 일반적으로 해당 스코프는 사라지게 됩니다. 더 이상 접근할 수 없는 상태가 되는 것이죠. 하지만 상황에 따라서( 대표적으로 비동기 작업이 끝나는 경우 ) 사라진 스코프 내부에서 정의한 클로저를 실행시켜야 할 때가 있습니다. 이때 실행되는 이 클로저를 escaping closure 라고 하는 것입니다.

```swift
func testEscaping(_ esClosure: @escaping (Int) -> Void) { 
  let urlRequest = URLRequest(url: URL(string: "hello world")!)
  var testCount = 3
	session.dataTask(with: urlRequest) { data, response, error in 
    print("world")
    esClosure(testCount)
  }.resume() 

  print("hello")
} 
```

대표적인 예제를 하나 살펴보겠습니다. testEscaping를 살펴보면 내부에서 asyncronous operation 인 dataTask가 있습니다. 그리고 dataTask의 completion Hanlder 에서 esClosure를 사용하는 것을 확인할 수 있습니다. testEscaping을 외부에서 실행하는 순간 "hello"가 로그로 찍히고 내부의 스코프는 접근할 수 없지만, dataTask 작업이 끝나고 completionHandler 가 실행되며 "wolrd" 가 로그에 찍히고 esClosure 가 캡쳐된 인자와 함께 실행되는 것을 확인할 수 있을 것입니다.

## Strong reference cycle for Closures

여태까지 escaping closure가 무엇인지, 어떻게 실행되는지, 왜 사용해야 하는지 등을 알아봤습니다. 하지만 escaping closure 뿐만 아니라 closure 자체를 사용할 때 주의해야할 점이 있는데, reference Value 를 캡쳐하게 될 때 Strong Reference Cycle 이 생길 수 있다는 점입니다. 

ARC 를 살펴보면 reference Type 의 값은 참조가 되는 경우 reference count 가 증가하고 0 이 될때 비로소 사라지게 됩니다. capturing values 또한 마찬가지로 변수에 값을 할당하는 것입니다. 이때 만약 self 에서 해당 클로저를 참조하고 클로저에서 self 를 참조하는 경우에 Strong Reference Cycle 이 생겨 인스턴스가 사라지지 않는 경우가 생길 수 있습니다. 이런 경우를 조심하고 Capture List 를 선언하여 이를 방지해야합니다.

이 포스트에서 정리를 하려고 했으나, 내용이 너무 길어질 것 같아서 관련된 ARC의 개념을 한번 정리를 한 다음 링크를 걸도록 하겠습니다. 자세한 내용을 알고싶다면 하단의 Strong Reference Cycle 관련 레퍼런스를 넣었으니 확인하시기를 바랍니다.



## reference

https://andybargh.com/lifetime-scope-and-namespaces-in-swift/#Scope

[Capturing Values]()

[Escaping Closure](https://docs.swift.org/swift-book/LanguageGuide/Closures.html#ID546)

[Strong Reference Cycles for Closures](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html#ID56)

[Resolving Strong Reference Cycles for Closures](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html#ID57)