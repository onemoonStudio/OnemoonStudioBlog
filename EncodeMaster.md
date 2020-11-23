# Encoding 정복하기

- knowledge Base
- SubClass Encode Issue
- encode ?
- container ?
- Tip

# Knowledge Base

이전 포스트와 동일하게 보편적으로 우리는 json 형식으로 데이터를 감싸는 방식을 자주 활용한다. 다시 한번 개념을 돌아보자면, 외부의 표현을 내부의 표현으로 변경하는 것이 decode, 내부의 표현을 외부의 표현으로 변경 하는 것이 encode 이다. 이때 외부의 표현은 여러가지로 해석될 수 있으며 해당 포스트에서는 JSON 형식을 갖춘 데이터이다.

사실 encode는 decode와 반대의 개념이기 때문에, 이전 포스트를 통해 decode는 어떤 방식으로 활용 했는지 알고 오는 것이 좋을 것이라고 생각한다. 또한 Codable(Encodable & Decodable)이 아닌 Encodable을 활용할 예정이고, 해당 프로토콜에 대한 설명과 기본 사용법은 [이 포스트](http://www.naver.com)를 참고하도록 하자. 

# SubClass Encode Issue

이전 Decode 포스트의 상황과 굉장히 유사하다. 유저의 데이터를 계속해서 보내야 한다고 생각해보자. 어떤 부분은 유저의 데이터 그리고 핸드폰 정보를 보내야 하는 반면, 어느 부분에서는 유저의 데이터와 함께 주소 정보를 보내야 한다. 동일한 유저의 데이터를 활용하기 위해서 상속을 통해서 해결하려고 한다. 

```swift
class UserData: Encodable {
    var name: String?
    var age: Int?
}

class UserAndPhone: UserData {
    var phone: String?
    var number: String?
}

class UserAndAddress: UserData {
    var address: String?
    var postCode: String?
}
```

그리고 이제 UserAndPhone의 정보를 모두 채우고 encode를 해보자. 우리가 원하는 방향은 name, age, phone, number의 정보를 모두 외부의 표현, 즉 JSON 형식으로 변경하는 것이다. 그런데 예측과는 다른 결과가 나온다.

```swift
let userAndPhone = UserAndPhone()
userAndPhone.name = "onemoon"
userAndPhone.age = 25
userAndPhone.phone = "iPhone X"
userAndPhone.number = "01012341234"

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let data = try encoder.encode(userAndPhone)
if let text = String(data: data, encoding: .utf8) {
    print(text)
}

//{
//  "name" : "onemoon",
//  "age" : 25
//}
```

분명히 phone 과 number 에 대한 데이터를 넣어 주었음에도 불구하고 데이터에는 생략 되었다. 왜 이런 일이 발생하는 걸까? 

이유는 상속에 있다. 객체를 데이터로 바꾸는 Encode과정을 생각해보면 JSONEncoder에서 각 객체의 encode함수를 호출해서 data를 만드는 것이다. UserAndPhone 의 [encode(_:)](https://developer.apple.com/documentation/foundation/jsonencoder/2895034-encode) 의 호출은 사실상 UserData의 encode만 호출되기 때문에 name과 age 만 데이터로 변환이 되는 것이다. 즉 이를 해결하기 위해서는 UserAndPhone(SubClass)에서 encode(_:)를 override 해주면 된다.

```swift
class UserAndPhone: UserData {
    var phone: String?
    var number: String?
    
    enum Keys: String, CodingKey {
        case phone
        case number
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(phone, forKey: .phone)
        try container.encode(number, forKey: .number)
    }
}

//{
//  "age" : 25,
//  "phone" : "iPhone X",
//  "number" : "01012341234",
//  "name" : "onemoon"
//}
```

생각해보면 굉장히 간단 하지만 에러가 나지 않기 때문에 꼼꼼하게 보지 않는다면 놓치기 쉬운 부분이다. 꼭 유념해서 encode를 진행 하기를 바란다.

# Encode ?

encode<T>(_ value: T)에 대해서 조금 더 자세하게 알아보자. 어떤 프로퍼티를 옵셔널로 선언하고 encode를 한다면 해당 키에 대한 정보는 보내지지 않을 것이다. 문제는 실제로 데이터를 다루다 보면 항상 예외 상황이라는 것이 존재한다. 특정 프로퍼티는 없으면 보내지 말고, 또 다른 프로퍼티는 없어도 기본 값으로 보낸다던지 말이다. 사실 개발을 하다가 이런 예외 상황을 마주치면 처리하기가 힘들거나 깔끔하게 코드를 작성하기 어렵다.

이때 encode를 직접 정의 해준다면 어느정도 해결 될지도 모른다. 게시물을 업데이트 하는 API를 호출하려고 한다. 

```swift
struct UpdatePostBody: Encodable {
    var user: UserData?
		var postId: String?
    var title: String?
    var content: String?
}
```

이때 서버 팀에서 user와 postId 는 항상 존재 해야한다고 한다. 만약 실수로 user 혹은 postId 에 nil이 들어가는 경우에는 키 값조차 전달되지 않기 때문에 디버깅에 문제가 생길 수 있다. 이 경우 다음과 같은 방식으로 데이터를 보낼 수 있을 것이다. 

```swift
// Version 1
struct UpdatePostBody: Encodable {
    var user: UserData?
    var postId: String?
    var title: String?
    var content: String?
    
    enum Keys: String, CodingKey {
        case user, postId, title, content
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(user ?? UserData(), forKey: .user)
        try container.encode(postId ?? "", forKey: .postId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(content, forKey: .content)
    }
}
// Version 2
struct UpdatePostBody: Encodable {
    var user: UserData = UserData()
    var postId: String = ""
    var title: String?
    var content: String?
}
```

Version 1 과 같이 encode를 작성한다면 user 와 postId 에 nil 이 들어가더라도 UserData() , 그리고 ""로 들어가게 될 것이다. container.encode의 경우에는 값이 무조건 존재해야 하며 해당 값을 통해서 매칭되는 키 값과 함께 데이터가 만들어진다. container.encodeIfPresent 의 경우 만약 값이 nil이라면 키 와 값 모두 보내지 않는다. 이렇게 데이터가 만들어진다. 물론 Version 2 처럼 작성을 해도 동일하게 encode는 동작을 할 것이다. 여기에서는 encode 가 저런 방식으로 작성이 된다는 것을 알아 두자. 다양한 활용 법은 아래에서 알아 볼 것이다.

# Container ?

함수의 구현을 살펴보면 container라는 struct를 확인해볼 수 있을 것이다. decode와 동일하게 container 는 다음과 같이 세가지 container로 분류된다.

1. KeyedEncodingContainer
2. UnKeyedEncodingContainer
3. SingleValueContainer

4. KeyedEncodingContainer의 경우 위에서 사용한 것과 같이 CodingKey를 채택한 타입이 필요하다. CodingKey에 들어온 키 값에 따라서 값들을 encode하여 data로 바꿀 수 있다. 

5. UnkeyedEncodingContainer 는 키가 없이 데이터 배열로 값을 변환하여 데이터로 만든다. 아래의 예시를 보는 것이 이해가 빠를 것이다.  타입도 다를 수 있으며 Key: Value 형태가 아니라는 것을 주목하자.

```swift
class UserData: Encodable {
    var name: String? = "onemoon"
    var age: Int? = 25
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(name)
        try container.encode(age)
    }
}

//[
//  "onemoon",
//  25
//]
```

3. SingleValueContainer 는 말 그대로 객체를 하나의 값인 데이터로 변경 해주는 것이다. 말 그대로 singleValue 이기 때문에 encode는 단 한번만 사용될 수 있으며, 여러번 encode를 하면 에러가 발생한다. 따라서 모든 값을 사용할 필요도 없으며 단 하나의 데이터 값만 표현하면 된다. 

```swift
class UserData: Encodable {
    var name: String? = "onemoon"
    var age: Int? = 25
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}

//"onemoon"
```

# Tip

- Enum 최대한 활용하기
- 데이터 조합하기 ( Data = struct + struct )

Enum을 활용하는 것과 데이터의 조합은 decode편에서도 다룬 내용이다. 단 decode에서는 init을 활용 했다면 encode에서는 함수를 활용 한다는 점이다. 

## Enum 최대한 활용하기

사실 데이터를 보내기 전에 UI 에서 부터 Enum으로 데이터를 자주 관리하는 편이다. 이 경우에도 동일하게 enum의 rawValue 대신에 따로 데이터에 들어갈 값을 설정해 줄 수 있다. 또한 만약 enum에 관련된 값을 따로 추출해서 보내야 하는 경우 어떻게 처리할까? 다음 예시를 생각해보자

```swift
enum Phone: String, Encodable {
    case galaxy
    case iPhone
    case pixel
    
    var textForEncode: String {
        switch self {
        case .iPhone:
            return "IPHONE"
        case .galaxy:
            return "GALAXY"
        case .pixel:
            return "PIXEL"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.textForEncode)
    }
    
    var os: String {
        switch self {
        case .iPhone:
            return "iOS"
        case .galaxy, .pixel:
            return "AOS"
        }
    }
}
```

rawValue 와 다르게 server에서는 모두 대문자로 변환된 값을 받아야 한다. 또한 phone의 기종과 더불어 OS 를 보내야 한다고 가정하자. 아래와 같이 쉽게 처리할 수 있다.

```swift
struct UserData: Encodable {
    var name: String?
    var age: Int?
    var phone: Phone?
    
    enum Keys: String, CodingKey {
        case name
        case age
        case phone
        case phoneOS
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(phone?.os, forKey: .phoneOS)
    }
}
//{
//  "age" : 25,
//  "phone" : "IPHONE",
//  "name" : "onemoon",
//  "phoneOS" : "iOS"
//}
```

여기서 두가지 부분을 한번 주목 해보자. 

첫번째 enum 에서 encode를 처리했기 때문에 encodeIfPresent(phone, forKey: .phone) 부분에는 rawValue가 아닌 대문자로 변환된 값이 들어간다.

두번째 phoneOS 라는 프로퍼티를 따로 만들어 줄 필요 없이 CodingKey만 따로 관리한다면 데이터를 보내는 키 값을 쉽게 처리할 수 있다는 점이다. Keys에 phoneOS라는 케이스를 만들고 이를 encode 에서 phone?.os로 처리할 수 있다. 이렇게 처리한다면 UI와 데이터의 변환이 편하게 될 것이다.

사실 Enum 뿐만 아니라 struct 나 class 등에 encode를 직접 구현 해준다면 코드가 상당부분 줄어듦과 동시에 관리 하기에도 훨씬 더 편해질 것이라고 장담한다. 예전에 나는 네트워크에서 받은 Entity를 통해서 업데이트를 위한 Body를 만들었는데, 이때 Body를 통해서 UI에 표현될 데이터와 실제로 보내질 데이터의 프로퍼티를 따로 관리했던 기억이 난다. (예를 들면 전자는 name 이 될 것이고, 후자는 Id값이 될 것이다.) 이 때문에 관리 해야하는 프로퍼티는 계속해서 불어나고 관리가 힘들었던 기억이 난다. 지금 이 지식을 알고 나서 작업 했다면 적어도 30%의 시간이 줄어들 것이라고 생각한다.

## 데이터 조합하기 ( Data = struct + struct )

서비스가 커지면 기존의 데이터 구조를 활용하는 것이 훨씬 더 간편한 경우가 많을 것이다. 이런 경우를 위해서 여러 개의 데이터를 조합해서 body를 직접 만들어 보자. 서버에서 원하는 구조와 현재 사용 되는 데이터가 다음과 같다고 생각해보자.

```swift
{
    "name": String
    "age": Int
    "kakaoProfileURL": String
    "kakaoId": String
    "howManyKakaoFriends": Int
}

struct UserData: Encodable {
    var name: String?
    var age: Int?
}

struct KakaoUserData: Encodable {
    var profileURL: String
    var id: String
    var friends: [KakaoUserData]
}
```

위와 같은 경우 UserData와 KakaoUserData를 조합한다면 쉽게 처리가 가능할 것이다. 일일이 다섯개의 프로퍼티를 갖고 있는 struct를 만들 필요가 없다. 아래를 살펴보자

```swift
struct KakaoUserBody: Encodable {
    var originUserData: UserData
    var kakaoUserData: KakaoUserData
    
    enum Keys: String, CodingKey {
        case name, age, kakaoProfileURL, kakaoId, howManyKakaoFriends
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encodeIfPresent(originUserData.name, forKey: .name)
        try container.encodeIfPresent(originUserData.age, forKey: .age)
        try container.encodeIfPresent(kakaoUserData.profileURL, forKey: .kakaoProfileURL)
        try container.encodeIfPresent(kakaoUserData.id, forKey: .kakaoId)
        try container.encodeIfPresent(kakaoUserData.friends.count, forKey: .howManyKakaoFriends)
    }
}
```

이렇게 두개의 객체 조합을 통해서 하나의 바디를 간단하게 만들 수 있다. Key 값을 직접 처리하여 마치 하나의 객체에 다섯 개의 프로퍼티가 있는 것 처럼 표현할 수 있으며, kakaoUserData.friends.count와 같이 필요한 경우 데이터를 변경해서 처리할 수도 있다.