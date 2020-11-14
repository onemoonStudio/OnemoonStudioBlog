# Decoding 정복하기

- Knowledge Base
- SubClass Decode 이슈
- Key가 없는 경우에 대한 이슈
- container ?
- Tip



## 들어가며

네트워크를 통해서 데이터를 주고 받을 때 우리가 편한 객체로 변환하거나 변환 되어서 데이터를 관리 하고는 한다. 해당 포스트는 데이터를 처리하는 방식에 대해서 말해 보고자 한다. 기본적인 개념도 있지만 그 보다는 실제로 데이터를 주고 받으면서 발생했던 이슈 들을 조금 더 집중해서 다루고 공유하기 위해서 해당 포스트를 작성하였다.



## Knowledge Base

API를 통해 데이터를 주고 받기 위해서는 json 형식이 보편적으로 사용된다. json으로 데이터를 쉽게 처리하기 위해서 우리는 Codable 혹은 Decodable, Encodable 프로토콜을 사용한다. ( 개인적으로 목적에 따라서 Decodable, Encodable 하나만 채택해서 사용하는 편이다. ) 해당 프로토콜에 대한 설명과 기본 사용법은 [이 포스트](http://www.naver.com)를 참고하도록 하자.



## Subclass Decode Issue

회사의 도메인 특성상 필드 그리고 엔티티가 굉장히 많고 세부적으로 나뉘어져 있다. 단순히 Struct로 모든 엔티티를 관리하기에는 많은 어려움이 있어 생각한 것이 Class inheritance 를 이용하는 것이었다.

하지만 처음에 상속받은 클래스를 Decode 하는 과정에서 이슈가 하나 있었는데 이 경험을 공유하고자 한다. 아래의 데이터를 보자

```swift
let jsonData = """
{
    "hello": "world",
    "wow": "wonderful",
    "onemoon": null
}
""".data(using: .utf8)!

let jsonData2 = """
{
    "hello": "world",
    "wow": "wonderful",
    "changed": "field"
}
""".data(using: .utf8)!
```

위와 같이 데이터가 들어온 경우 <hello, wow> 필드를 공통으로 가지는 클래스를 만들고 <onemoon>, <chagned> 필드를 각각 가지는 Subclass 를 아래와 같이 만들었다.

```swift
class A: Decodable {
    var hello: String
    var wow: String
}
class Aa: A {
    var onemoon: String?
}
class Ab: A {
    var chagned: String?
}

let jsonDecoder = JSONDecoder()
do {
    let subClassData = try jsonDecoder.decode(Aa.self, from: jsonData)
    let subClassData2 = try jsonDecoder.decode(Ab.self, from: jsonData2)
    print("SUCCESS \\n")
    dump(subClassData)
    dump(subClassData2)
} catch let err {
    print("FAIL")
    print(err.localizedDescription)
}

// 결과 값 
// SUCCESS
//
//▿ __lldb_expr_7.Aa #0
//  ▿ super: __lldb_expr_7.A
//    - hello: "world"
//    - wow: "wonderful"
//  - onemoon: nil
//
//▿ __lldb_expr_7.Ab #0
//  ▿ super: __lldb_expr_7.A
//    - hello: "world"
//    - wow: "wonderful"
//  - chagned: nil
```

결과적으로 SUCCESS 와 두 객체가 로그에 남지만, 실제로는 제대로 decode가 되지 않았다. 문제는 catch 구문을 거치지 않기 때문에 놓치기 쉬울 수 있다. 실제로 배포가 된 이후, 나중에서야 파악이 될 수도 있다는 것이다.

아래의 객체와 데이터를 살펴보자. <hello, wow> 필드는 제대로 값을 받아 왔지만 < changed > 필드는 값을 받아오지 못한다. 왜 제대로 decode 가 되지 않았을까 ?

알고 보면 굉장히 단순하다. Ab 클래스가 Decode 될 때 **required init(from decoder: Decoder)** 가 제대로 호출되지 않았기 때문이다. 상속의 특성을 생각해보자 subclass 에서 별도로 initializer 를 설정하지 않는 이상, subclass의 initializer 대신 super class 의 initializer가 호출이 된다.

따라서 Ab 클래스 대신 A의 init만 호출 되었기 때문에 A의 필드인 <hello, wow>만 제대로 값을 가져온 것이다. 이를 해결하기 위해서는 Ab 클래스에서 init을 다시 작성하면 된다.

```swift
class Ab: A {
    var chagned: String?
    enum Keys: String, CodingKey {
        case changed
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.chagned = try container.decode(String?.self, forKey: .changed)
        try super.init(from: decoder)
    }
}

//SUCCESS
//▿ __lldb_expr_15.Ab #0
//  ▿ super: __lldb_expr_15.A
//    - hello: "world"
//    - wow: "wonderful"
//  ▿ chagned: Optional("field")
//    - some: "field"
```

Ab Class 에서 decoder를 통한 init이 호출이 되고 < chagned > 필드를 decode 한 다음, super.init을 통해서 부모클래스인 A 에서도 init이 호출 됨을 파악할 수 있다. 이로써 온전하게 상속받은 클래스를 decode 할 수 있다.

## Key가 없는 경우에 대한 Issue

실제로 데이터를 주고 받는 과정에서 키 값이 일정하지 않고 유동적으로 변경되는 상황이 종종 일어나고는 한다. 이 상황에서의 문제점은 Decoding 된 객체를 아예 만들지 못한다는 점인데, 자칫하면 UI를 그리지 못하기 때문에 사용성이 굉장히 떨어질 수 있다. 아래 예시를 살펴보자.

```swift
// origin Data -> Good
{ 
"name": "onemoon",
"thumbnailURL": "<https://ooo.com>"
}

// changed Data -> Bad ( Swift.DecodingError.keyNotFound )
{ 
"name": "onemoon"
}

struct UserData: Decodable {
    let name: String
    let thumbnailURL: String
}
```

위와 같이 thumbnailURL 을 받아 오다가 어떠한 이유로 인해서 더 이상 해당 키에 대한 값이 사라지는 경우 DecodingError.KeyNotFound 에러가 발생하고 UserData는 생성되지 않는다. 이에 대한 해결책을 생각해보자.

첫번째, 키 값이 없는 프로퍼티의 타입이 옵셔널인 경우에는 ( thumnailURL: String? 인 경우 ) 해당 에러가 발생하지 않는다.

두번째 ,만약 옵셔널을 처리하기 번거롭거나 기본 값이 필요한 경우에는 다음과 같이 Decode에 실패한 경우 할당할 수 있다.

```swift
struct UserData: Decodable {
    let name: String
    let thumbnailURL: String
    
    enum Keys: String, CodingKey {
        case name, thumnailURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.thumbnailURL = (try? container.decode(String.self, forKey: .thumnailURL)) ?? "default Thumbnail URL"
    }
}
```

세번째, container.decodeIfPresent를 활용하는 것이다. 값 자체에 옵셔널을 처리하는 방식과 동일한데 이런 방식도 있다는 것을 참고하도록 하자.

```swift
struct UserData: Decodable {
    var name: String
    var thumbnailURL: String?
    
    enum Keys: String, CodingKey {
        case name, thumnailURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumnailURL)
				// 키가 있는 경우 decode를 진행하고 없는 경우 nil을 할당한다.
    }
}
```

참고로 init(decoder:)을 직접 구현하는 경우 모든 프로퍼티를 정확하게 써야 하는데, 놓칠 수 있으니 주의를 하도록 하자. 현재는 프로퍼티가 let 으로 선언이 되어서 init에 하나의 프로퍼티라도 빠지는 순간 에러가 발생하지만 var로 선언한 경우 경우는 실제로 데이터가 있어도 값을 가져오지 못하는 경우가 생길 수 있기 때문이다. 아래를 간단하게 참고하도록 하자

```swift
// Data
{
"name": "onemoon"
}

struct UserData: Decodable {
    var name: String?
    var thumbnailURL: String
    
    enum Keys: String, CodingKey {
        case name, thumnailURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
				// name 에 대한 decode를 실수로 작성하지 못한 경우
        self.thumbnailURL = (try? container.decode(String.self, forKey: .thumnailURL)) ?? "default Thumbnail URL"
    }
}

// Log ::: UserData(name: nil, thumbnailURL: "default Thumbnail URL")
// 값을 제대로 가져오지 못하는 것을 확인할 수 있다.
```

## Container ?

포스트를 작성하다가 container 에 대해서 조금 더 알아봤을 때 container(keyedBy:) 말고도 singleValueContainer(), unkeyedContainer()의 존재를 알게 되었다. 간단하게 짚고 넘어 가보자

### SingleValueContainer

Key : Value 가 아닌 단순히 값 하나만 들어온 경우 이를 decode할 수 있다.

```swift
// jsonData2 > "hello singleValueContainer"

struct SimpleData: Decodable {
    let text: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.text = try container.decode(String.self)
    }
}

print(try! JSONDecoder().decode(SimpleData.self, from: jsonData2))
// Log ::: SimpleData(text: "hello singleValueContainer")
```

### unkeyedContainer

배열에서 타입이 일정하지 않은 경우를 생각해보면 해당 container로 쉽게 해결할 수 있다.

```swift
// jsonData3 > ["a", 1, true, 20.0, 50.0]

struct SpecialArrayData: Decodable {
    var a: String?
    var b: Int?
    var c: Bool?
    var d: Double?
//    var e: Double?
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        a = try container.decode(String?.self)
        b = try container.decode(Int?.self)
        c = try container.decode(Bool?.self)
        d = try container.decode(Double?.self)
//        e = try container.decode(Double?.self)
    }
}

print(try! JSONDecoder().decode(SpecialArrayData.self, from: jsonData3))

// Log ::: SpecialArrayData(a: Optional("a"), b: Optional(1), c: Optional(true), d: Optional(20.0))
```

참고로 해당 container는 데이터와 객체 프로퍼티의 순서를 맞춰야 한다는 것에 유의하도록 하자.

특히 unkeyedcontainer가 재밌다고 느껴졌는데, 복잡한 데이터에서 원하는 값만 추출할 때 유용하게 사용할 수 있을 것 같다. 아마 내부적으로 3가지의 container를 JSON data에 맞춰 적절히 사용하여 Decodable이 구현되었을 것이라고 생각한다.

## Tip

- Enum 최대한 활용하기
- 데이터 조합하기 ( Data = struct + struct )

포스팅을 작성하면서 여러 가지를 느꼈다. 이전에 내가 겪었던 이슈들도 생각해보고 이렇게 저렇게 활용하면 좋겠다는 생각이 들었다. 내가 느끼고 활용할 수 있는 방식들을 직접 테스트 해보고 공유하고자 한다. 지금 이 섹션이 가장 많은 도움이 될 것이라고 생각을 한다.

### Enum 최대한 활용하기

먼저 Enum을 생각해보자 나는 Decoding을 할때 만약 데이터가 몇 가지의 케이스로 나뉘어서 들어온다면, String으로 그냥 값을 decoding 하는 것 보다는 Enum 을 최대한 활용하는 편이다. 보통 다음과 같이 사용한다.

```swift
enum Phone1: String, Decodable {
    case iPhone
    case galaxy
    case pixel = "Pixel"
}
```

이렇게 되면 Enum의 RawValue 가 Key처럼 되어 "iPhone"이라는 텍스트가 들어온다면 Phone1.iPhone으로 활용할 수 있는 것이다. 하지만 다음과 같은 상황에서는 Enum을 통해 Decoding 하기가 힘들어진다.

1. RawValue를 이미 다른 값 ( Int, Double ) 로 사용하는 경우, 이를 다시 String으로 변경하거나 처리하는 과정이 복잡하다. ( 혹은 귀찮다. )
2. [associated Value](https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html#ID148) 를 사용하는 경우 RawValue를 사용할 수 없다. 따라서 decodable을 채택하는 순간 에러가 발생한다.
3. 데이터 자체가 결함(?)이 있는 경우 ( 앞 글자가 대문자, 변환이 필요한 경우 등등... )

해당 포스트를 작성하기 전에는 나도 위와 같은 경우 대부분 String으로 처리를 하거나 다른 방식을 찾았던 것 같다.  그렇다면 이 과정을 어떻게 하면 쉽게 처리할 수 있을까? 방법은 init(from:)를 직접 활용하면 된다. 아래 예시를 보자

```swift
// User1Phone > "blackberry"
// User2Phone > "IPHONE"

enum Phone: Decodable {
    case iPhone
    case galaxy
    case pixel
    case uncommon(whatKind: String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        var value = try container.decode(String.self)
        value = value.lowercased() // 받아온 데이터를 직접 처리할 수 있다.
        
        if value == "iphone" {
            self = .iPhone
        } else if value == "galaxy" {
            self = .galaxy
        } else if value == "pixel" {
            self = .pixel
        } else {
            self = .uncommon(whatKind: value)
        }
    }
}

print(try! JSONDecoder().decode(Phone.self, from: User1Phone)) // uncommon(whatKind: "blackberry")
print(try! JSONDecoder().decode(Phone.self, from: User2Phone)) // iPhone
```

이렇게 직접 decoder를 작성하는 순간 위에서 언급한 세가지 이슈가 모두 해결 된다. 1. RawValue는 신경 쓸 필요가 없어진다. 2. 따라서 RawValue를 신경 안쓰고 decoder에서 직접 값을 만들어 주면 된다 ( uncommon 확인 ). 3. 데이터가 중간에 대문자가 포함되어 있거나 값을 처리해야 하는 경우도 직접 처리하면 된다.

### 데이터 조합하기 ( Data = struct + struct )

서비스를 하다 보면 분명히 기존에 사용한 데이터가 잘 정리 되어 있을 것이다. 이는 서버도 마찬가지이다. 만약 User와 Device라는 데이터를 분리해서 ( 혹은 다른 키 값으로 ) 가져오다가, 어느날 두 가지를 합쳐서 준다면 어떻게 처리할까? 아래 예시를 한번 보자

```swift
// 기존에는 User 혹은 Device만 따로 데이터가 오는 경우 활용한 struct 들
struct UserEntity: Decodable {
    var name: String
    var age: Int

		enum Keys: String, CodingKey {
        case name, age
    }
}

struct DeviceEntity: Decodable {
    var name: String
    var capacity: String
    
    enum keys: String, CodingKey {
        case name = "phoneName"
        case capacity = "phoneCapacity"
    }
}
// 새로운 데이터
var newUserAndPhoneData = """
{
"name": "onemoon",
"age": 25,
"phoneName": "iphone 12",
"phoneCapacity": "256G"
}

""".data(using: .utf8)!
```

데이터를 보자 마자 드는 생각은 두 개를 합치면 되겠다는 생각이 들 것이다. 현실은 그렇게 호락호락 하지 않지만 ( 이전의 나.... ) 이래서 사람은 배워야 하나보다.

위와 같은 경우도 손쉽게 해결할 수 있다. 생각하는 그 방식이 맞다.

```swift
struct UserAndDevice: Decodable {
		var user: UserEntity
    var device: DeviceEntity
}
```

물론 이렇게 하고 끝나면 안된다. UserAndDevice는 Key값이 user 와 device인 경우에만 동작하기 때문이다. 이를 아래와 같이 바꿔 보자

```swift
struct UserAndDevice: Decodable {
    var user: UserEntity
    var device: DeviceEntity
    
    init(from decoder: Decoder) throws {
        let userContainer = try decoder.container(keyedBy: UserEntity.Keys.self)
        self.user = UserEntity(name: try userContainer.decode(String.self, forKey: .name),
                               age: try userContainer.decode(Int.self, forKey: .age))

        let deviceContainer = try decoder.container(keyedBy: DeviceEntity.keys.self)
        self.device = DeviceEntity(name: try deviceContainer.decode(String.self, forKey: .name),
                                   capacity: try deviceContainer.decode(String.self, forKey: .capacity))
    }
}
```

간단하게 생각해서 받아온 데이터로 user 그리고 device를 생성 하면 되는 것이다. 따라서 기존에 UserEntity 와 DeviceEntity 의 CodingKey를 직접 가져와 container 를 생성하여 데이터를 decode 한 것을 확인할 수 있다.

한가지 더 생각 해보면 사실 UserAndDevice를 만들기 위해서, UserEntity 혹은 DeviceEntity는 Decodable을 채택할 필요가 없다는 것이다. 직접 decoder를 정의 해주니 decodable이 아닌 error가 나타나지 않을 것이다. 아래 예시로 대답을 마무리 하겠다.

```swift
struct UserEntity {
    var name: String
    var age: Int
}
enum UserKey: String, CodingKey {
    case name, age
}
// UserAndDevice ...
init(from decoder: Decoder) throws {
  let userContainer = try decoder.container(keyedBy: UserKey.self)
  self.user = UserEntity(name: try userContainer.decode(String.self, forKey: .name),
                         age: try userContainer.decode(Int.self, forKey: .age))
  let deviceContainer = try decoder.container(keyedBy: DeviceEntity.keys.self)
  self.device = DeviceEntity(name: try deviceContainer.decode(String.self, forKey: .name),
                             capacity: try deviceContainer.decode(String.self, forKey: .capacity))
}
```

내가 든 예시는 극히 일부분이고 데이터가 점점 더 복잡해지고 처리 하면서 init(from decoder:)를 직접 활용 해보면 생각보다 많은 수고가 들지 않을 것이라고 생각한다.