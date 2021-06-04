# Property Wrapper

문서의 예시와 더불어 설명이 부족한 부분은 직접 중간 중간에 추가하였습니다.



Swift 5.1 부터 사용이 가능하며 다양한 기능이 있는 프로퍼티를 만들 수 있다고 생각하시면 됩니다.



간단한 정의와 더불어 몇개의 예시를 들면서 어떻게 사용하는 지 배워보겠습니다. 레퍼런스는 하단에 준비되어 있습니다. property wrapper 란 값을 저장하는 코드와 정의하는 코드를 분리시킬 수 있도록 하는 레이어를 추가하는 것입니다. 예를 들어 몇가지 프로퍼티에서 값을 가져올때 thread-safe 를 체크하거나, 값을 저장할 때 database 에 저장해야 한다면 모든 프로퍼티에 일일이 설정을 해줘야 할 것입니다. 이런 반복되는 작업을 없애고 특정 프로퍼티에 프로퍼티 래퍼를 추가함으로써 공통된 코드를 없앨 수 있는 것입니다. 한번 프로퍼티 래퍼를 정의한다면 다양한 프로퍼티에서 이를 쉽게 재사용할 수 있습니다.

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

@propertyWarpper 어노테이션을 붙인 뒤 structure 내부에서 wrappedValue를 정의한 것을 확인할 수 있습니다. 참고로 내부에 number는 private으로 외부에서 접근을 할 수 없는데, 이는 주어진 방식을 통해서 저장 혹은 값을 읽는 처리를 하기 위함이라고 이해하시면 됩니다.



사용하는 방법 또한 굉장히 간단합니다. @{propertyWrapperName} 을 통해서 위에서 정의한 PropertyWrapper 를 사용할 수 있습니다. 초기값은 정의된 값으로, 10을 넣은 경우 12와 비교해서 낮은 값은 10이 들어가게 되고, 12를 초과하는 경우는 12가 할당됩니다. 



## 초기값 정의하기

상단에서는 Property Wrapper 를 정의하는 곳에서 초기값을 정의했습니다. 이런 방식은 다른 초기값을 설정해 줄 수 없다는 문제점이 발생합니다. 초기값 그리고 customization을 지원하기 위해서 initializer를 추가할 수 있습니다. 아래의 예시를 보겠습니다.



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

height 그리고 width를 할당하는 것을 살펴보겠습니다. Swift에서는 PropertyWrapper 에 초기값을 할당하게 되면 ( = 1 ) init(wrappedValue:) 이니셜라이저가 사용됩니다. 따라서 min(1, 12) 를 통해서 1이 할당되므로 Prints "1 1"이 결과로 나오는 것입니다.



그렇다면 init(wrappedValue:maximum:) 은 어떻게 사용할까요? 어노테이션을 사용하면서 이니셜라이저를 사용하면 됩니다.  아래의 예시를 보면 쉽게 이해를 할 수 있습니다. 

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

상단 프로퍼티부터 설명하겠습니다. height은 init(wrappedValue: 2, maximum: 5) 를 통해서 선언된 프로퍼티이며, width는 init(wrappedValue: 3, maximum: 4)를 통해서 선언된 것으로 확인할 수 있습니다. 따라서 첫번째 프린트에서는 "2 3"이 나오며, 이후에 100을 할당하고 다시 프린트 한 경우는 maximum값이 나오는 것을 확인할 수 있습니다.



Swift 에서는 assignment(할당)을 wrappedValue 에 인자를 넘기는 것과 동일하게 생각합니다. 따라서 wrappedValue와 다른 arguments가 결합된 형태라면 다음과 같은 방식으로 사용할 수도 있습니다.

```swift
struct MixedRectangle {
    @SmallNumber var height: Int = 1
    @SmallNumber(maximum: 9) var width: Int = 2
}


var mixedRectangle = MixedRectangle()
print(mixedRectangle.height)
// Prints "1"

mixedRectangle.height = 20
print(mixedRectangle.height)
// Prints "12"
```

이때 height은 init(wrappedValue: 1), width는 init(wrappedValue:2, maximum: 9)을 사용해서 프로퍼티가 생성됩니다.



## Projecting a Value From a Property Wrapper

property wrapper는 wrapped value와 더불어서 projected value라는 기능을 하나 더 가질 수 있습니다. projected value는 $ 로 시작하는 것을 제외하고는 wrapped value와 동일합니다. 다만 $가 들어간 변수는 사용자가 정의할 수 없기 때문에 사용자가 정의한 속성을 방해하지는 않습니다.



property wrapper는 정의에 따라서 사용자가 할당한 값 이외에 다른 값이 할당되는 경우가 있습니다. 이때 projected value property 는 값이 할당되기 전 어떠한 변환 작업을 거쳤는지 확인할 수 있도록 해줍니다. 아래의 예제를 살펴보겠습니다.



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

아래에서 4를 할당한 경우는 그대로 값이 들어가게 될 것입니다. 따라서 변환이 이루어지지 않았기 때문에 someStructure.$someNumber ( projected value )는 false 가 됩니다. 반대로 55를 할당한 경우 변환이 들어가고 projectedvalue 는 true가 됩니다.



property wrapper 는 어느 타입이던 상관없이 projected value를 정의하고 리턴할 수 있습니다. 예시에서는 Bool 값을 사용했지만 더 많은 정보가 필요하다면 Data Type 을 따로 정의해 리턴 할 수도 있으며, 자기 자신을 리턴할 수도 있습니다. 이를 위해서는 단순히 projectedValue 라는 이름의 프로퍼티에 값을 정의해주면 됩니다. 아래는 projected value를 String으로 사용하는 예시입니다.



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















## Reference

https://docs.swift.org/swift-book/LanguageGuide/Properties.html#ID617

https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md