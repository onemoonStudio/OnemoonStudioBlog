# Property Wrapper

이번에는 Swift 5.1 부터 사용이 가능해진 Property Wrapper 에 대해서 알아보겠습니다. 간단하게 요약하자면 Property Wrapper 는 getter와 setter 관련된 로직을 포함하고 있는 프로퍼티를 쉽게 선언할 수 있도록 합니다. 문서의 예시와 더불어 설명이 부족한 부분은 직접 중간 중간에 추가하였습니다. 모든 레퍼런스는 하단에 준비되어 있습니다.



간단한 정의와 더불어 몇 개의 예시를 들면서 어떻게 사용하는 지 배워보겠습니다. Property Wrapper 의 정확한 정의는 값을 저장하는 코드와 정의하는 코드를 분리시킬 수 있도록 하는 레이어를 추가하는 것입니다. 예를 들어 몇가지 프로퍼티에서 값을 가져올때 thread-safe 를 체크하거나, 값을 저장할 때 database 에 저장해야 한다면 모든 프로퍼티에 일일이 설정을 해줘야 할 것입니다. 이런 반복되는 작업을 없애고 특정 프로퍼티에 Property Wrapper를 추가함으로써 공통된 코드를 없앨 수 있습니다. 한번 Property Wrapper를 정의한다면 다양한 프로퍼티에서 이를 쉽게 재사용할 수 있습니다.

## 정의 및 사용 예시

이런 Property Wrapper 를 정의할 때에는 structure, enumeration, class 를 통해서 wrappedValue 를 정의해줘야 합니다. 문서에 있는 Property Wrapper의 정의와 사용법에 대한 예시를 보겠습니다.

```swift
// Definition - 최대 12의 값을 가질 수 있는 프로퍼티를 만들고 싶다.
@propertyWrapper
struct TwelveOrLess {
    private var number = 0
    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, 12) }
    }
}	
// Use
struct SmallRectangle {
    @TwelveOrLess var height: Int
    @TwelveOrLess var width: Int
}

var rectangle = SmallRectangle()
print(rectangle.height)
// Prints "0"

rectangle.height = 10
print(rectangle.height)
// Prints "10"

rectangle.height = 24
print(rectangle.height)
// Prints "12"

```

@propertyWarpper 를 선언한 이름의 어노테이션 ( @{propertyWrapperName} )을 붙인 뒤 Structure 내부에서 wrappedValue를 정의한 것을 확인할 수 있습니다. 참고로 내부에 number는 private으로 외부에서 접근을 할 수 없는데, 이는 주어진 방식을 통해서 저장 혹은 값을 읽는 처리를 하기 위함이라고 이해하시면 됩니다. 사용하는 방법 또한 굉장히 간단합니다. 사용하고자 하는 프로퍼티 앞 혹은 위에 @{propertyWrapperName} 을 통해서 위에서 정의한 PropertyWrapper 를 사용할 수 있습니다. 

TwelveOrLess 예시를 확인해보면 먼저 최대 12의 값을 가질 수 있는 Property Wrapper 를 정의하였습니다. 이후 height 과 width 프로퍼티를  Property Wrapper와 함께 선언해주었습니다. 이후 0을 할당한 경우 그대로 0 이 들어가며 마찬가지로 10을 할당한 경우 그대로 10이 할당됩니다. 여기서 height 에 24를 할당한 경우는 @TwelveOrLess 의 setter에서 정의한 대로 24와 12중 작은 값인 12가 할당됩니다.

## 초기값 정의하기

상단에서는 Property Wrapper 내부에서 초기 값을 정의했습니다. 이렇게 내부에서 처리하는 방식은 다른 초기값을 설정해 줄 수 없다는 문제점이 발생합니다. 초기값 그리고 Customization을 지원하기 위해서 PropertyWrapper 에서도 initializer를 추가할 수 있습니다. 아래의 예시를 보겠습니다.



```swift
// Definition
@propertyWrapper
struct SmallNumber {
    private var maximum: Int
    private var number: Int

    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, maximum) }
    }

    init() {
        maximum = 12
        number = 0
    }
    init(wrappedValue: Int) {
        maximum = 12
        number = min(wrappedValue, maximum)
    }
    init(wrappedValue: Int, maximum: Int) {
        self.maximum = maximum
        number = min(wrappedValue, maximum)
    }
}
// Use
struct UnitRectangle {
    @SmallNumber var height: Int = 1
    @SmallNumber var width: Int = 1
}

var unitRectangle = UnitRectangle()
print(unitRectangle.height, unitRectangle.width)
// Prints "1 1"

```

여기에서 height = 1 부분을 주목하시기를 바랍니다. 이렇게 직접 할당을 하는 경우 Property Wrapper 는 init(wrapperValue:) 를 찾아 이를 생성하려고 합니다. 만약 해당 이니셜라이저 대신 하나의 argument 를 가지지만 다른 프로퍼티를 초기화하는 intializer 가 있는 경우는 어떻게 될까요? 이 경우는 에러가 발생하여 원하는 결과를 얻을 수 없습니다.

```swift
@propertyWrapper
struct SmallNumber { 
  ...
  init(test: Int) {
    self.maximum = test
    self.number = test
  }
}

// ...
// Error: incorrect argument label in call (have 'wrappedValue:', expected 'test:')
@SmallNumber var height: Int = 1

```

그렇다면 init(wrappedValue:maximum:) 은 어떻게 사용할까요? 어노테이션을 사용하면서 이니셜라이저를 사용하면 됩니다. 아래의 예시를 보면 쉽게 이해할수 있습니다.

```swift
struct NarrowRectangle {
    @SmallNumber(wrappedValue: 2, maximum: 5) var height: Int
    @SmallNumber(wrappedValue: 3, maximum: 4) var width: Int
}

var narrowRectangle = NarrowRectangle()
print(narrowRectangle.height, narrowRectangle.width)
// Prints "2 3"

narrowRectangle.height = 100
narrowRectangle.width = 100
print(narrowRectangle.height, narrowRectangle.width)
// Prints "5 4"
```

해당 예제에서 height은 init(wrappedValue: 2, maximum: 5) 를 통해서 생성된 프로퍼티이며 초기값은 2를 가지고 최댓값은 5가 될 것입니다. width의 경우 init(wrappedValue: 3, maximum: 4)를 통해서 생성된 프로퍼티로 초기값은 3을 가지고 최댓값은 4가 될 것입니다. 따라서 첫번째 프린트에서는 초기값인 "2 3"이 나오는 것을 확인할 수 있으며, 이후에 각각 프로퍼티에 100을 할당하고 다시 프린트 한 경우는 각자의 최댓값이 나오는 것을 확인할 수 있습니다.



여기에서 조금 더 변형된 initalizer를 고려해보자면 아래와 같습니다. Swift 에서 PropertyWrapper의 assignment(할당)는 wrappedValue 에 인자를 넘기는 것과 동일하게 생각합니다. 따라서 wrappedValue와 다른 arguments가 결합된 형태라면 할당된 값은 wrappedValue에 전달되며 나머지 인자는 따로 구현을 해줘야 합니다. 아래의 예제를 살펴보겠습니다.

```swift
struct MixedRectangle {
    @SmallNumber var height: Int = 1 
  	// init(wrappedValue: 1)
    @SmallNumber(maximum: 9) var width: Int = 2
    // init(wrappedValue: 2, maximum: 9)
}

var mixedRectangle = MixedRectangle()
print(mixedRectangle.height)
// Prints "1"
mixedRectangle.height = 20
print(mixedRectangle.height)
// Prints "12"
```

width를 살펴보면 2를 할당하고 maximum은 따로 설정한 것을 확인할 수 있습니다. 제대로 보지 않으면 순서가 헷갈릴 수 있지만, 할당 자체가 wrappedValue 인자로 전달된다는 것을 인지한다면 크게 어렵지 않을 것입니다.

## Projecting a Value From a Property Wrapper

Property Wrapper는 Wrapped Value와 더불어서 Projected Value라는 예약어가 있습니다. Projected Value는 $ 로 시작하는 것을 제외하고는 Wrapped Value와 동일합니다. 다만 이를 사용할 때는 $를 붙여서 사용하며 해당 값은 사전에 정의된 로직을 제외하고 따로 조작할 수 없다는 차이점이 있습니다. 아래 예제와 함께 설명하겠습니다.

```swift
@propertyWrapper
struct SmallNumber {
    private var number = 0
    var projectedValue = false
    var wrappedValue: Int {
        get { return number }
        set {
            if newValue > 12 {
                number = 12
                projectedValue = true
            } else {
                number = newValue
                projectedValue = false
            }
        }
    }
}
struct SomeStructure {
    @SmallNumber var someNumber: Int
}
var someStructure = SomeStructure()

someStructure.someNumber = 4
print(someStructure.$someNumber)
// Prints "false"

someStructure.someNumber = 55
print(someStructure.$someNumber)
// Prints "true"

```

우리가 배운 것 처럼 Property Wrapper는 정의에 따라서 사용자가 할당한 값 이외에 다른 값으로 변환되는 경우가 있습니다. 예제에서는 Projected Value를 이용해서 변환이 이루어졌는지 확인할 수 있도록 하였습니다. 따라서 4를 할당한 경우 변환이 이루어지지 않았기 때문에 Projected Value인 someStructure.$someNumber 는 false 를 리턴합니다. 하지만 55를 할당한 경우 내부 정의에 따라서 변환이 이루어졌기 때문에 해당 값은 true가 됩니다.

Property Wrapper는 어느 타입이던 상관없이 Pojected Value를 정의하고 리턴할 수 있습니다. 예시에서는 비교적 단순한 Bool 값을 사용했지만 더 많은 정보가 필요하다면 Data Type 을 따로 정의해 리턴 할 수도 있으며, 자기 자신을 리턴할 수도 있습니다. 이를 위해서는 단순히 projectedValue 라는 이름의 프로퍼티에 값을 정의해주면 됩니다. 아래는 Pojected Value를 String으로 사용하는 예시입니다.

```swift
@propertyWrapper
struct SmallNumber {
    private var number = 0
    var projectedValue: String = ""
    var wrappedValue: Int {
        get { return number }
        set {
            if newValue > 12 {
                number = 12
                projectedValue = "world"
            } else {
                number = newValue
                projectedValue = "hello"
            }
        }
    }
}
struct SomeStructure {
    @SmallNumber var someNumber: Int
}
var someStructure = SomeStructure()

someStructure.someNumber = 4
print(someStructure.$someNumber)
// Prints "hello"

someStructure.someNumber = 55
print(someStructure.$someNumber)
// Prints "world"
```



이렇게 문서를 참고하고 예시를 덧붙여서 개념을 알아봤습니다. 그렇다면 이런 Property Wrapper를 어떻게 사용하는지 그리고 왜 사용하는지에 대해서 한번 알아보겠습니다. 예시는 [Proposals 문서](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md)를 참고하여 작성하였습니다.



### How : User Default

처음 Property Wrapper의 개념을 공부하고 나서 User Default를 PropertyWrapper를 통해 사용한다면  정말 편하겠다는 생각을 했습니다. 마침 swift-evolution 문서에도 이 방식으로 Example을 제안한 것을 확인할 수 있었습니다. 값을 추출하는 방식과 값을 저장하는 방식을 미리 정의하고 이를 사용한다면 자동으로 User Default 에 원하는 값이 저장되고 추출 될 것입니다. 아래는 문서에서의 예시 입니다.

```swift
@propertyWrapper
struct UserDefault<T> {
  let key: String
  let defaultValue: T
  
  var wrappedValue: T {
    get {
      return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
    }
    set {
      UserDefaults.standard.set(newValue, forKey: key)
    }
  }
}

enum GlobalSettings {
  @UserDefault(key: "FOO_FEATURE_ENABLED", defaultValue: false)
  static var isFooFeatureEnabled: Bool
  
  @UserDefault(key: "BAR_FEATURE_ENABLED", defaultValue: false)
  static var isBarFeatureEnabled: Bool
}

```

먼저 예시에서 보이는 것 처럼 Property Wrapper는 제네릭으로도 사용이 가능합니다. 또한 필요한 부분들을 할당하지 않고 initializer 처럼 생성할 수 있습니다. 따라서 User Default 에 접근하기 위한 key 그리고 만약 값이 존재하지 않은 경우 defulatValue를 생성시에 받는 것을 확인할 수 있습니다. get 구문에 의해서 어떤 key의 값을 가져올 때 UserDefault 를 확인하고 만약 값이 nil이라면 defaultValue를 리턴하는 것을 확인할 수 있으며, set에 의해서 propertyWrapper 를 변경해준다면 해당 값이 UserDefault 에 저장되는 것을 확인할 수 있습니다. 예시에서는 Bool 값을 FOO_FEATURE_ENABLED, BAR_FEATURE_ENABLED 키를 통해서 UserDefault에 접근하는 것을 확인할 수 있습니다.

### How : Delayed Initialization

Swift 에서는 Lazy 라는 키워드가 있습니다. 해당 키워드를 변수에 사용하게 되면 해당 값이 불릴 때 비로소 값이 할당되도록 하는 키워드 입니다. 보통 클래스 혹은 struct 에서 다른 프로퍼티를 참고하여 값을 할당해야 하는 경우 사용하게 됩니다. 해당 객체는 아직 생성되지 않았기 때문에 프로퍼티를 만드는 당시에 다른 프로퍼티를 참고할 수 없습니다. 따라서 Lazy 를 이용해 객체가 생성된 이후 시점에서 해당 값을 사용하는 로직을 위해 사용합니다. 이런 방식을 Property Wrapper 를 통해서도 구현이 가능합니다. 일단 프로퍼티와 타입을 정의해 놓고 값은 나중에 할당하는 방식입니다. 아래의 예시를 보겠습니다.

```swift
@propertyWrapper
struct DelayedMutable<Value> {
  private var _value: Value? = nil

  var wrappedValue: Value {
    get {
      guard let value = _value else {
        fatalError("property accessed before being initialized")
      }
      return value
    }
    set {
      _value = newValue
    }
  }

  /// "Reset" the wrapper so it can be initialized again.
  mutating func reset() {
    _value = nil
  }
}

// 이렇게만 선언해도 컴파일 에러가 발생하지 않습니다.
@DelayedMutable var hello: String

```

물론 DelayedMutable를 사용한다면 예상치 못한 경우 fatalError 가 발생할 수 있기 때문에 이를 Lazy 대신에 사용하는 것은 좋지 않은 방법입니다. 여기에서는 Lazy 또한 이런식으로 구현할 수 있겠구나 라고 생각하시면 될 것 같습니다. 또한 문서에 DelayedImmutable 이라는 PropertyWrapper 가 있는데 흥미로운 방식이니 이를 참고하시는 것 또한 추천드립니다.



## 마무리

이렇게 Property Wrapper 를 간단하게 알아봤습니다. 우리가 모듈이나 별도의 로직이 들어간 함수를 만들어 여러 곳에서 사용하는 것처럼 Property Wrapper 또한 프로퍼티를 위한 함수라고 생각해도 될 것 같습니다. 생각보다 Customization 이 굉장히 열려 있으며 ProjectedValue를 통해서 다양한 방식으로 활용이 가능한 것을 확인할 수 있었습니다. 이를 활용해서 다양한 방식으로 코드의 중복을 낮추고 효율을 높이셨으면 좋겠습니다. 



## Reference

https://docs.swift.org/swift-book/LanguageGuide/Properties.html#ID617

https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md