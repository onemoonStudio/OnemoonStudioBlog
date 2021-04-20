# Swinject 사용하기

저번 포스팅에서 SOLID를 공부한 이유는 사실 DI를 이해하고 이를 적용하기 위함이었다. 직접 프로토콜을 설계하고 작업하려다가 기존에 나와있는 DI Library 는 어떻게 활용하는지 궁금해서 문서를 읽고 예제를 만들어봤다. 오늘 소개할 라이브러리는 [Swinject](https://github.com/Swinject/Swinject) 라는 DI Library 이고, 추가로 SwinjectStoryboard를 간단하게 사용할 예정이다.

이번 포스팅에서는 문서에서 중요하다고 생각한 부분들을 추리고, 예제 및 문서의 코드를 직접 활용하면서 어떻게 사용했는지 설명 할 생각이다. 문서의 양이 얼마 되지 않으니 한번 전체를 읽어보고 다시 와서 핵심을 파악하는 것을 추천한다. 



## Container

DI Container 로 이해하면 되며, 사실상 Swinject의 핵심이라고 할 수 있다. Container 에 원하는 serviceType을 register 하면 된다. 이후에 필요한 곳에서 resolve를 통해 해당 타입에 맞는 객체가 생성되어 나온다. 샘플 프로젝트에서 예시를 가져왔다.

```swift
let container = Container()
// CocktailNameListViewModeling (protocol)
// CocktailNameListViewModel (class)
// register
container.register(CocktailNameListViewModeling.self) { (_, alphabet: String) in
	return CocktailNameListViewModel(alphabet)
}
// resolve
let viewModel = container.resolve(CocktailNameListViewModeling.self, argument: targetAlphabet(at: indexPath))

```

ViewModel 을 실제로 등록하고 사용하는 부분의 코드이다. `CocktailNameListViewModeling`이라는 protocol을 serviceType 으로 등록하고 해당 프로토콜을 채택한 `CocktailNameListViewModel`을 리턴하도록 container 에 등록한다.

이후 ViewModel을 injection 해줘야 하는 부분에서 resolve를 통해 구체화된 객체 `CocktailNameListViewModel`을 가져온다. 이때는 등록할때의 클로저(factory closure) 에 필요한 인자들을 넘길 수 있다.

### register 가 중복되는 경우는?

이 문서를 봤을 때 궁금했던 점은 동일한 프로토콜을 여러 곳에서 사용하려면 ( 여러 구현체가 있다면 ) 어떻게 해야할까? 라는 점이었다. 결론부터 말하자면 내부적으로 생성되는 Key인 `Registration Key` 를 통해서 구분할 수 있다. 라이브러리에 구현된 코드를 가져왔으며 이를 보면서 설명하겠다.

```swift
// Container.arguments.swift
@discardableResult
public func register<Service, Arg1>(
	_ serviceType: Service.Type,
	name: String? = nil,
	factory: @escaping (Resolver, Arg1, ...) -> Service
) -> ServiceEntry<Service> {
	return _register(serviceType, factory: factory, name: name)
}	
```

container 에 등록을 할때 내부적으로 `Registration Key` 가 생성되어 서로를 구분하게 된다. 이때의 키는 위에서 register 할때의 인자 3가지 를 통해서 구분하는 것을 확인할 수 있다. 인자는 다음과 같이 설명할 수 있다.

1. type of the service ( serviceType )
2. name of registration
3. number and type of the arguments

이 덕분에 동일한 타입을 등록하더라도 다른 register 함수와의 차이를 판단하고 서로 다른 구현체를 resolve 할 수 있다. 2번에 대한 설명을 문서에 있는 코드와 함께 설명하겠다. 문서의 코드를 확인해보면 `name: "cat"` 라는 인자를 넘긴 것을 확인할 수 있다. 

```swift
container.register(Animal.self, name: "cat") { _ in Cat(name: "Mimi") }	
```

또한 Registration Key를 구분하는 3가지의 인자중 하나라도 다른 경우 nil을 리턴하게 되니 이를 조심해야 한다.

## Circular Dependencies

Swinject를 사용하면 자동으로 서로 resolve 되도록 설계할 수 있고, 이를 통해서등록이 되니 편함을 느낄 수 있다. 이때 만약 A를 만들때 B가 필요하고 B를 만들때 A가 필요한 `Circular Dependencies`가 생긴다면 이는 어떻게 해야할까? 생각해보면 생성하는 단계에서 무한으로 서로 resolve 할 가능성이 있어 보인다. 

이를 해결하기 위해서는 A와B 둘중 하나라도 property injection이 들어가야 한다고 문서에서 설명한다. **즉 intializer/initialzer dependencies는 지원하지 않는다.** [injection 에 대한 설명은 문서](https://github.com/Swinject/Swinject/blob/master/Documentation/InjectionPatterns.md)에서 확인할 수 있고, 아래는 Initializer/Property Dependencies의 코드를 예시로 가져왔다.

```swift
protocol ParentProtocol: AnyObject { }
protocol ChildProtocol: AnyObject { }
// initializer injection
class Parent: ParentProtocol {
    let child: ChildProtocol?
    init(child: ChildProtocol?) {
        self.child = child
    }
}
// property injection
class Child: ChildProtocol {
    weak var parent: ParentProtocol?
}
```

initCompleted closure 에서 필요한 dependency를 property injection 방식으로 넘기면 된다. 이를 통해서 아래와 같이 사용하면 Circular Dependencies 를 해결할 수 있다.

```swift
let container = Container()
container.register(ParentProtocol.self) { r in
    Parent(child: r.resolve(ChildProtocol.self)!)
}
container.register(ChildProtocol.self) { _ in Child() }
    .initCompleted { r, c in
        let child = c as! Child
        child.parent = r.resolve(ParentProtocol.self)
     }
```

## Object Scope

resolve를 통해서 생성된 객체를 유지하려면 어떻게 해야할까? 혹은 생성된 인스턴스의 lifecycle은 어떻게 될까? 해당 부분에 대한 설명은 Object Scope를 통해서 할 수 있다. Swinject 에서 제공하는 Object Scope는 4가지이다.

1. Transient

Transient 를 사용한다면 Instance는 공유되지 않는다. 즉 resolve를 할 때마다 Instance 가 생성된다. Circular Dependencies 에서 사용하는 경우는 주의를 해야한다.



2. Graph(default)

Transient 와 비슷하게 container 에서 resolve 를 하는 경우 항상 생성한다. Transient와의 차이는 factory closure에서 resolve 를 하게 되는 경우 resolution이 끝날때 까지 해당 인스턴스는 공유된다는 점이다.



3. Container

다른 DI frameworks의 singleton이라고 생각하면 된다. container 를 통해서 생성된 instance 는 해당 container 그리고 chile containers(child containers 가 궁금하다면 [Container Hierarchy](https://github.com/Swinject/Swinject/blob/master/Documentation/ContainerHierarchy.md) 문서를 확인해보자)까지 공유가 된다. 

다시 말해서 어떤 container 에서 A 타입을 register 한 이후에 resolve 를 하게 되면, 이후 A 타입에 대한 resolve 는 앞서 생성한 instance 가 동일하게 리턴된다. ( 동일한 객체 )



4. Weak

재미있는 케이스이다. instance를 strong 으로 잡고 있는 경우는 Container 처럼 서로 공유하지만 더 이상 strong reference 가 없는 경우 더 이상 공유되지 않는다. 이후 resolve를 하게 되면 새로운 인스턴스가 생성이 된다.

### Custom Scope

위에서 설명한 4가지 스코프는 Swinject에서 정한 스코프이다. 이 외에도 직접 Scope를 만들어서 사용할 수 있는데 이를 Custom Scope라고 한다. 이때 container scope 처럼 공유가 되는데 필요에 따라서 객체들을 reset 할 수 있다는 차이가 있다. 

```swift
// 생성
extension ObjectScope {
    static let custom = ObjectScope(storageFactory: PermanentStorage.init)
}
// 제거
container.resetObjectScope(.custom)
```

조금 더 자세하게 알고 싶다면 [해당 블로그](https://felginep.github.io/2019-02-05/swinject-in-practice)에서 확인해보자



## Assembly

위와 같이 container 자체로 활용할 수도 있지만 만약 도메인별로 관리하고 싶은 경우는 어떻게 해야할까? 혹은 연관된 기능들을 필요한 부분만큼만 관리하고 싶다면 어떻게 해야할까? 

연관된 서비스를 그룹화하는 기능을 제공하기 위해서 Swinject 에서는 `Assembly` 라는 프로토콜을 제공한다. 이를 통해서 아래와 같은 기능을 사용할 수 있다.

- 하나의 장소에서 여러개의 서비스를 관리할 수 있음
- 공유된 Container 를 제공함
- 서로 다른 설정을 가진 assembly를 등록할 수 있다. 따라서 mock implement에 유리하다.
- 제대로 설정이 되면 ( 등록 과정이 끝나면 ) 알림을 받을 수 있다.

물론 다 옵션이므로 필요한 부분만 사용하면 된다. 아래 예시 코드를 간단하게 가져왔다. ManagerAssembly 에서 ServiceAssembly 에서 등록한 protocol을 사용하는 것을 확인할 수 있다. 

```swift
class ServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(FooServiceProtocol.self) { r in
           return FooService()
        }
        container.register(BarServiceProtocol.self) { r in
           return BarService()
        }
    }
}

class ManagerAssembly: Assembly {
    func assemble(container: Container) {
      // 다른곳에서 등록한 protocol 또한 활용할 수 있다.
        container.register(FooManagerProtocol.self) { r in                                                     
           return FooManager(service: r.resolve(FooServiceProtocol.self)!)
        }
        container.register(BarManagerProtocol.self) { r in
           return BarManager(service: r.resolve(BarServiceProtocol.self)!)
        }
    }
}
```



### Assembler

하지만 위의 코드는(Assembly) 리소스를 준비하는 과정이고, 실제로 사용하기 위해서는 `Assembler` 를 사용해야 한다. 여러 곳에서 준비된 `Assembly`들을 잘 조합해서 `Assembler`를 사용하는 것이다.

```swift
let assembler = Assembler([
    ServiceAssembly(),
    ManagerAssembly()
])

let fooManager = assembler.resolver.resolve(FooManagerProtocol.self)!
// or lazy load assemblies
assembler.applyAssembly(LoggerAssembly())
```

Assembler 는 Assemblies 그리고 Container 를 관리한다. Assembler 를 통해서 등록된 Assembly 들만 Container 에서 사용할 수 있다는 것을 기억해두자. 또한 resolve하기 위해서 접근하는 resolver는 assembler의 resolver(assembler.resolver) 로 제한이 된다.



## Thread Safety

Swinject는 concurrent applications 로 구현이 되어있다. 따라서 Container 는 thread safe 하지 않다. 하지만 이를 thread safe 하도록 하는 방법이 있는데 synchronize method를 이용해서 리턴되는 resolver를 사용하는 것이다.

```swift
let container = Container()
container.register(SomeType.self) { _ in SomeImplementation() }
let threadSafeContainer: Resolver = container.synchronize()
// Do something concurrently.
for _ in 0..<4 {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        let resolvedInstance = threadSafeContainer.resolve(SomeType.self)
        // ...
    }
}
```

container 가 thread safe 하지만 이는 `resolve`에만 해당하는 이야기이다. `register` 는 여전히 thread safe하지 않다. 따라서 registeration 은 단일 쓰레드에서 실행이 되어야 한다. 

또한 만약 container 가 hierarchy 를 갖고 있다면 연결된 모든 컨테이너는 synchronize()를 사용해야 한다는 점을 알아두자



## Example - CocktailMaster

Swinject, SwinjectStoryboard를 사용해서 칵테일을 검색하고 이를 만들기 위해서 어떤 요소들이 필요한지 확인할 수 있는 간단한 예제를 만들었다. [여기](https://github.com/onemoonStudio/CocktailMaster)에서 확인할 수 있으며 [태그](https://github.com/onemoonStudio/CocktailMaster/tags)를 확인해보면 Container만을 사용하는 seperatedContainer 태그와 Assembly를 활용한 assembly 태그가 있다. 각각 다운받은 뒤 pod install 을 실행하고 확인해볼 수 있다.







































