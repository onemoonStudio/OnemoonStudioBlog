# Increasing Performance Reducing Dynamic Dispatch

프로그램의 성능을 높히기 위해서 Dynamic Dispatch 를 줄이는 방법이 있다. 그렇다면 Dynamic Dispatch란 무엇이고 이를 줄이면서 어떻게 성능이 개선되는지 한번 알아보자

### Dispatch

먼저 Dispatch 의 개념부터 알아보도록 하자. Dispatch는 어떤 메소드를 호출할 것인가를 결정하여 그것을 실행하는 과정이다. Dispatch 방식은 Static Dispatch, Dynamic Dispatch로 두가지가 있다.

### Static Dispatch

컴파일 시점에 어떤 메소드가 사용될지 명확하게 결정되는 것을 Static Dispatch 라고 한다.

### Dynamic Dispatch

런타임 시점에 어떤 메소드가 실행될지 결정되는 것, 즉 컴파일 시점에서는 어떤 함수가 실행될 지 모른다. Swift 에서는 class 마다 vtable을 갖고 있고 이를 참조하면서 함수가 호출되기 때문에 이에 따른 overhead가 발생하게 된다. 

### Static VS Dynamic Dispatch

위의 설명만 들으면 이해가 잘 안될수도 있다. 아래 예시를 살펴보자

```swift
// Static Dispatch
struct HelloStruct {
  func printHello() {
    print("hello")
  }
}
let helloStruct = HelloStruct()
helloStruct.printHello()
```

struct 는 Value Type 이다. 즉, 다른곳에서 해당 값의 레퍼런스를 가지고 있을 필요가 없으며 상속도 되지 않는다. 따라서 컴파일러의 시각에서 생각해보면 

helloStruct.printHello() 는 HelloStruct의 printHello()가 호출된다는 것이 명확해진다. 즉 다른 방법이 없다. 이때 Static Dispatch 방식으로 함수가 호출되는 것이다.

```swift
// Dynamic Dispatch
class HelloClass {
  func printHello() {
    print("hello")
  }
}

class HelloOtherClass: HelloClass { }

let helloClass: HelloClass = HelloOtherClass()
helloClass.printHello()
```

class 는 Reference Type 이며 Struct 와 다르게 상속이 가능해진다. 다른 곳에서도 함수를 호출할 가능성이 존재한다는 것이다. 위의 helloClass 변수를 보자 타입은 HelloClass 지만 실제 값은 HelloOtherClass 의 인스턴스이다. 실제로 함수가 override 되었는지 안 되었는지는 중요하지 않다. 즉, 컴파일러가 봤을 때 printHello()가 상속으로 인해서 다른 클래스에서 호출될수도 있겠구나 그러면 바로 HelloClass 의 printHello를 직접 접근하지 말고 참조 형식으로 둬야 겠다 라는 방향으로 컴파일을 한다는 것이다. 따라서 특별하게 지정하지 않는 이상 해당 함수는 Dynamic Dispatch 로 인해서 불리게 된다.



## Increasing Performance by Reducing Dynamic Dispatch

이제 본문으로 돌아오면 스위프트도 다른 언어와 마찬가지로 여러 method 혹은 properties 를 슈퍼클래스로부터 override 할 수 있다. 이는 다시말해서 프로그램이 런타임시에 indirect call & indirect access 를 통해서 어떤 method 혹은 property를 호출하는지 정하는 것을 말한다. 이를 다이나믹 디스패치라고 말하고 indirect usage 를 사용할 때 마다 overhead 가 발생하게 된다. 따라서 성능이 중요한 코드에서는 이런 overhead 는 바람직하지 못하다. 이런 역동성을 제거하는 방식에는 크게 3가지가 있고 예시와 함께 이를 설명하겠다. 

먼저 역동성을 제거하지 않은 예시를 살펴보자

```swift
class ParticleModel {
	var point = ( 0.0, 0.0 )
	var velocity = 100.0

	func updatePoint(newPoint: (Double, Double), newVelocity: Double) {
		point = newPoint
		velocity = newVelocity
	}

	func update(newP: (Double, Double), newV: Double) {
		updatePoint(newP, newVelocity: newV)
	}
}

var p = ParticleModel()
for i in stride(from: 0.0, through: 360, by: 1.0) {
	p.update((i * sin(i), i), newV:i*1000)
}
```

위의 코드가 실행이 된다면 컴파일러는 dynamic dispatch call을 방출하는데 순서는 다음과 같다.

1. Call update on p.
2. Call updatePoint on p.
3. Get the property point tuple of p.
4. Get the property velocity of p.

ParticleModel의 Method나 Property 를 override 해서 새로운 구현을 하기 위해서는 이런 dynamic dispatch는 필수적이다 ( 즉, 반대는 필요 없다는 말 ). Swift에서는 Dynamic Dispatch를 구현할 때 Method Table에서 해당 function을 찾고 indirect call을 호출한다. 이는 direct call보다 느리며 compiler 의 최적화 방향에도 좋지 않은 영향을 미친다. 따라서 성능을 높히기 위해서는 이런 방향을 지향해야 한다.

#### Use Final

> Use final when you know that a declaration does not need to be overridden.

 해당 키워드는 클래스의 method 혹은 property 에 override 를 제한한다. 따라서 컴파일러는 이로 인한 indirect call, access 를 무시할 수 있다. 

```swift
class ParticleModel {
	final var point = ( x: 0.0, y: 0.0 )
	final var velocity = 100.0

	final func updatePoint(newPoint: (Double, Double), newVelocity: Double) {
		point = newPoint
		velocity = newVelocity
	}

	func update(newP: (Double, Double), newV: Double) {
		updatePoint(newP, newVelocity: newV)
	}
}		
```

final keyword를 붙힌 point, velocity, updatePoint() 를 살펴보자. 이제 point 와 velocity 의 경우 직접적으로 객체의 stored property 에 접근할 수 있게되며, updatePoint() 또한 direct function call로 호출할 수 있게 된다. 따라서 overhead 가 줄어들고 성능이 향상된다. 하지만 여전히 update()는 dynamic dispatch를 통해 indirect function call 로 호출이 되며 overhead 가 발생하고, 성능이 안좋아졌지만 서브클래스에서 override 가 가능하다. 

```swift
final class ParticleModel {
	var point = ( x: 0.0, y: 0.0 )
	var velocity = 100.0
	// ...
}
```

final은 이렇게 class 앞에도 붙힐 수 있으며 이때는 클래스에서 구현된 모든 property 와 method는 direct call로 불리게 되고 override 가 불가능하다.

#### applying the private keyword

> Infer final on declarations referenced in one file by applying the private keyword.

정의할 때 private keyword를 사용하는 것은 참조할 수 있는 곳을 현재 파일로 제한한다는 뜻이다. 따라서 컴파일러는 private 키워드가 참조될 수 있는 곳에서 잠재적으로 override 가 될 수 있는지 없는지를 판단한다. 이때 따로 override 하는 곳이 없다면 스스로 final 키워드를 추론하고 indirect call & access 을 제거한다.

```swift
class ParticleModel {
	private var point = ( x: 0.0, y: 0.0 )
	private var velocity = 100.0

	private func updatePoint(newPoint: (Double, Double), newVelocity: Double) {
		point = newPoint
		velocity = newVelocity
	}

	func update(newP: (Double, Double), newV: Double) {
		updatePoint(newP, newVelocity: newV)
	}
}
```

이 또한 위의 final 과 마찬가지로 클래스 앞에 private Keyword를 붙이게 되면 내부의 모든 property 그리고 method에도 private keyword가 붙힌 것으로 간주된다. 

```swift
private class ParticleModel {
	var point = ( x: 0.0, y: 0.0 )
	var velocity = 100.0
	// ...
}
```

#### Whole Module Optimization

> Use Whole Module Optimization to infer final on internal declarations.

internal access level(default 접근 제한자)은 정의된 모듈 내에서만 접근이 가능하다. 기본적으로 swift complier 는 모듈별로 컴파일을 하기 때문인데. 컴파일러는 기본적으로 internal access level에 대해서 서로 다른 파일에서 override 되었는지 확인이 불가능하다. 만약 whole module optimization 을 사용한다면 모든 모듈을 한번에 compile을 하게 된다. 따라서 이때 internal level 에 대해서 override가 되는지 추론을 할 수있게 되고  그렇지 않은 경우 내부적으로 final을 붙힌다. ( 따라서 direct call을 하게 된다. ) 아래 예시를 살펴보자

```swift
public class ParticleModel {
	var point = ( x: 0.0, y: 0.0 )
	var velocity = 100.0

	func updatePoint(newPoint: (Double, Double), newVelocity: Double) {
		point = newPoint
		velocity = newVelocity
	}

	public func update(newP: (Double, Double), newV: Double) {
		updatePoint(newP, newVelocity: newV)
	}
}

var p = ParticleModel()
for i in stride(from: 0.0, through: times, by: 1.0) {
	p.update((i * sin(i), i), newV:i*1000)
}
```

이때 whole module Optimization 을 키게 된다면 point, velocity, updatePoint() 에 대해서 자동으로 final을 추론하게 되고 direct call로 호출할 수 있게 되는것이다.

> 참고로 Xcode 8 부터 Whole Module Optimization은 release 할 때 켜져 있습니다. 프로젝트파일에서 build setting - Compilation Mode 를 확인하면 release 에서 whole module을 확인할 수 있습니다.



### Reference

[wiki - 동적 디스패치](https://ko.wikipedia.org/wiki/%EB%8F%99%EC%A0%81_%EB%94%94%EC%8A%A4%ED%8C%A8%EC%B9%98)

[Swift의 Dispatch 규칙](https://jcsoohwancho.github.io/2019-11-01-Swift%EC%9D%98-Dispatch-%EA%B7%9C%EC%B9%99/)

[Apple Blog - Increasing Performance Reducing Dynamic Dispatch ](https://developer.apple.com/swift/blog/?id=27)

[Swift.org - Whole-Module Optimization](https://swift.org/blog/whole-module-optimizations/)

