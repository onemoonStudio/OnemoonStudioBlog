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
<div>
<img src="/Users/hyeontaekim/Documents/Dev/GitHub/OnemoonStudioBlog/images/swinject_cm_1.PNG" style="zoom:30%;" />
<img src="/Users/hyeontaekim/Documents/Dev/GitHub/OnemoonStudioBlog/images/swinject_cm_2.PNG" style="zoom:30%;" />
<img src="/Users/hyeontaekim/Documents/Dev/GitHub/OnemoonStudioBlog/images/swinject_cm_3.PNG" style="zoom:30%;" />
</div>
첫번째 화면에서는 어떤 알파벳으로 시작하는 칵테일을 볼 것인지를 선택한다. 이 셀을 누르게 되면 두번째 화면으로 넘어간다.

두번째 화면은 해당 알파벳으로 시작하는 칵테일 리스트를 볼 수 있다. 여기에서 셀을 누르게 되면 세번째 화면으로 넘어간다.

세번째 화면에서는 칵테일의 디테일 요소를 보여준다. ingredient 또한 확인하여 어떻게 구성되어있는지 확인할 수 있다.



칵테일을 검색하고 이를 만들기 위해서 어떤 요소들이 필요한지 확인할 수 있는 간단한 예제를 만들었다. MVVM 구조를 따르도록 하였으며 Swinject, SwinjectStoryboard를 사용하여서 어플리케이션을 구성하였다. [여기](https://github.com/onemoonStudio/CocktailMaster)에서 예제를 확인할 수 있으며 [태그](https://github.com/onemoonStudio/CocktailMaster/tags)를 확인해보면 Container만을 사용하는 `seperatedContainer 태그`와 Assembly를 활용한 `assembly 태그`가 있다. 각각 다운받은 뒤 pod install 을 하고 앱을 실행하여 확인해볼 수 있다.

### SwinjectStoryboard 

Storyboard 에 있는 뷰컨트롤러를 만들 때에도 dependency를 관리하고 싶은 경우 활용하면 좋다. SceneDelegate.swift 에 있는 코드를 가져왔다.

```swift
lazy var initialContainer: Container = {
  let container = Container()
  container.register(MainViewModeling.self) { _ in 
		return MainViewModel() 
	}
  container.storyboardInitCompleted(MainViewController.self) { (r, c) in 
		// initCompleted closure
		c.viewModel = r.resolve(MainViewModeling.self) 
	}
  return container
}()
// ....
let mainViewController = SwinjectStoryboard
													.create(name: "Main", bundle: nil, container: initialContainer)
													.instantiateViewController(withIdentifier: "MainViewController")
```

MainViewController 에는 MainViewModel이 필요한데 이 뷰모델은 MainViewModeling 이라는 프로토콜을 채택해야 한다. 또한 MainViewController 에서는 구현체인 MainViewModel 이 아니라 MainViewModeling을 참조하도록 만들었다. 

MainViewController가 생성되면 자동으로 MainViewModel이 생성되어 injection이 된다. 이 과정을 아래와 같은 단계로 풀어서 설명할 수 있다.

1. MainViewModeling 을 register 한다. resolve를 하게되면 MainViewModel instance가 생성될 것이다.
2. SwinjectStoryboard.create 를 통해서 만들고자 하는 Storyboard 그리고 identifier 를 연결한다. 이때 container 인자에 사용하고자 하는 container 를 등록한다.
3. 2에서 사용한 container 에 container.storyboardInitCompleted를 사용하여 initCompleted closure 에 viewModel 을 property injection 형태로 넣어준다.

위와 같은 과정을 거치면 MainViewController를 만들었을 때 자동으로 ViewModel 이 injection 된 ViewController instance 를 얻을 수 있다.

### SwinjectStoryboard 단점

한가지 아쉬웠던 점은 SwinjectStoryboard.create 를 통해서 인자를 넘길 수 없다는 점이었다. 예를 들어서 MainViewModel에 `id: String`가 필요하다고 하자 SwinjectStoryboard.create 단계에서 id 인자를 넘기면 MainViewModeling을 resolve 할 때 이를 넣어주는 형태가 되었으면 조금 더 활용도가 높았을 텐데 하는 아쉬움이 있다. 문서를 찾아봤지만 이렇다 할 해법이 나와있지 않아 굉장히 아쉬웠다.

따라서 만약 ViewModel을 만들 때 어떤 인자가 필요하다면 initCompleted 를 사용하는 방식이 아닌, ViewController와 ViewModel을 각각 resolve 한 뒤 직접 injection 하는 방식으로 사용하거나, viewModel의 ObjectScope를 변경하여 관리하는 방식으로 사용해야 한다. 아래 예제에 설명이 나와있다.

## tag - seperatedContainer

위에서 말했다시피 예제 코드를 보면 두가지의 태그가 있다 이중 첫번째 seperatedContainer 에 대한 간단한 설명을 하고자 한다. seperatedContainer는 필요한 경우 viewModel에서 container 를 만들어서 이를 활용하는 방식으로 어플리케이션을 구성하였다. 아래의 코드는 MainViewModel.swift 에서의 코드이다.

```swift
protocol MainViewModeling: BaseViewModeling {
    var alphabetListRelay: BehaviorRelay<[String]> { get }
    var cocktailNameListViewControllerRelay: PublishRelay<CocktailNameListViewController> { get }
    func targetAlphabet(at indexPath: IndexPath) -> String
    func didTapAlphabetCell(at indexPath: IndexPath)
}

final class MainViewModel: BaseViewModel, MainViewModeling {
    let alphabetListRelay = BehaviorRelay<[String]>(value: [])
    let cocktailNameListViewControllerRelay = PublishRelay<CocktailNameListViewController>()
    
    let container = Container()
    
    override init() {
        super.init()
        setAlphabetList()
        setContainer()
    }
    
    private func setAlphabetList() {
			// ...
    }
    
    private func setContainer() {
        container.register(CocktailNameListViewModeling.self) { (_, alphabet: String) in
            return CocktailNameListViewModel(alphabet)
        }
        
        container.storyboardInitCompleted(CocktailNameListViewController.self) { (r, c) in
            // do somthing if u want ...
        }
    }
    
    func targetAlphabet(at indexPath: IndexPath) -> String {
        // ...
    }
    
    func didTapAlphabetCell(at indexPath: IndexPath) {
        let viewModel = container.resolve(CocktailNameListViewModeling.self, argument: targetAlphabet(at: indexPath))
        guard let viewController = SwinjectStoryboard.create(name: "Main", bundle: nil, container: container).instantiateViewController(withIdentifier: "CocktailNameListViewController") as? CocktailNameListViewController else { return }
        viewController.viewModel = viewModel
        
        cocktailNameListViewControllerRelay.accept(viewController)
    }
}

```

SwinjectStoryboard를 설명하는 단계에서 나온 MainViewModeling , MainViewModel이다. MainViewModeling은 BaseViewModeling protocol을 채택하여야 한다.

이제 container를 보도록 하자 container를 만들고 init단계에서 setContainer()를 호출하여 register 를 하였다. 이후 MainViewController 에서 셀을 누르는 경우 didTapAlphabetCell(at: IndexPath) 가 실행된다. 여기서 다음 단계인 CocktailNameListViewController 를 만들기 위한 작업이 이루어진다.

CocktailNameListViewController에 필요한 ViewModel protocol은 CocktailNameListViewModeling protocol이며, 구현체가 CocktailNameListViewModel이 된다. 이때 CocktailNameListViewModel에는 리스트를 가져올 알파벳을 알아야 하기 때문에 인자로 alphabet을 받게 된다. 

따라서 viewModel을 따로 resolve 하면서 targetAlphabet을 넣어준 다음, SwinjectStoryboard.create 를 통해서 만들어진 ViewController 에 만들어진 viewModel을 넣었다. 만들어진 ViewController는 relay에 넘겨서 navigationPush를 할 수 있도록 하였다.

### Container의 단점?

사용은 편하게 하였으나 확장성에 의문이 생겼다. 만약 다른 곳에서 register 한 요소들을 가져오려면 어떻게 해야할까? 혹은 여기서 등록한 요소를 다른곳에서 어떻게 활용할 수 있을까?

[Container Hierarchy](https://github.com/Swinject/Swinject/blob/master/Documentation/ContainerHierarchy.md) 를 살펴보면 parent - child 형태로 연결된 container에서 parent container 내부에 등록된 요소들은 child container 에서 resolve 가 가능하다. ( 반대는 안된다. ) 이를 활용하면서 object scope를 적절하게 사용한다면 어느 정도 확장성에 대한 해결이 될것이라고 생각한다.

## tag - assembly

위에서 말한 container hierarchy 를 사용하면 마치 클래스의 상속처럼 parent - child 형식으로 범위를 넓혀나갈 수 있을 것 같다. 하지만 프로토콜과 같이 어디서든 쉽게 붙였다 떼었다 할 수 있으면 조금 더 활용도가 높을 것 같다는 생각이 들었다. 문서를 살펴보니 assembly protocol이 있었고, parent-child hierarchy를 사용하는 것 또한 가능했으며, 이를 프로젝트에 직접 활용해보았다.

```swift 
// MainViewModel.swift
class MainAssembly: Assembly {
    func assemble(container: Container) {
        container.register(CocktailNameListViewModeling.self) { (_, alphabet: String) in
            return CocktailNameListViewModel(alphabet)
        }
    }
}
// CocktailNameListViewModel.swift
class CocktailListAssembly: Assembly {
    func assemble(container: Container) {
        container.register(CocktailDetailViewModeling.self) { (_, id: String) in
            // 제대로 assemble이 되었는지 확인하는 로그
            let test = container.resolve(CocktailNameListViewModeling.self, argument: "z")
            if let test = test as? CocktailNameListViewModel {
                print("Integration")
                print(test.startedAlphabet)
            } else {
                print("not Integrated")
            }
            
            return CocktailDetailViewModel(id)
        }
    }
}
// 실제 사용하는 코드
let assembler = Assembler([MainAssembly(), CocktailListAssembly()])
...
let viewModel = assembler.resolver ~> (CocktailDetailViewModeling.self, argument: selectedCocktail.idDrink)
// assembler.resolver.resolve(...) 과 동일하다.
// ~> 는 SwinjectAutoregistration을 받으면 사용할 수 있다.
```

먼저 SwinjectAutoregistration를 사용해서 ~> 라는 기호를 사용했는데 여기에서는 특별한 의미가 없고 단순 resolve를 저렇게 표현했다고 생각하면 된다. 관심이 있다면 해당 라이브러리도 참고 하는것을 추천한다.

제일 중요하게 봐야될 키워드는 `Assembly` 그리고 `Assembler` 이다. Assembly는 서로 다른 파일에 구현이 되어있다. 그리고 사용이 되는 코드에 Assembler 를 보면 MainAssembly 그리고 CocktailListAssembly 두개를 합친 것을 볼 수 있다. 그리고 CocktailListAssembly 에서 CocktailDetailViewModeling를 resolve 할때 MainAssembly에 등록된 프로토콜이 제대로 resolve 되는지 확인하기 위한 로그도 남겨놓았다.

개인적으로는 Assembly를 사용하는 것이 Container 를 사용하는 것 보다 조금 더 확장성이 있다고 느껴진다. 어떤 파일에 있던 가져올 수 있다면 쉽게 붙였다 떼는것이 가능할 뿐 더러, hierarchy 그리고 objectScope 모두 지원한다. 



## 마치며

글이 이렇게 길어질지는 몰랐는데 생각보다 설명할 부분이 많았던 것 같다. 이 내용을 토대로 앞으로 프로젝트를 Assembly를 활용하여 관리할 생각이다. 또한 이번에 SwinjectAutoregistration를 제대로 활용하지는 않았는데 이 또한 활용하면 재밌을 것 같다는 생각이 들었다. 한번 활용해보고 예제를 만들어 tag 를 추가하게 된다면 이 포스트에 사용법을 적어놓을 예정이다. 많은 도움이 되었기를 바라며 마치겠다. 👏

( 언제든지 피드백은 환영입니다. 👍🏻 )



## Reference

[직접 만든 예제 - CocktailMaster](https://github.com/onemoonStudio/CocktailMaster)

[예제에서 사용한 API - CocktailDB](https://www.thecocktaildb.com/)

[Swinject](https://github.com/Swinject/Swinject)

[Swinject - Document](https://github.com/Swinject/Swinject/tree/master/Documentation)

[SwinjectStoryboard](https://github.com/Swinject/SwinjectStoryboard)

[SwinjectAutoRegistration](https://github.com/Swinject/SwinjectAutoregistration)

[laywenderlich - Swinject Tutorial for iOS: Getting Started](https://www.raywenderlich.com/17-swinject-tutorial-for-ios-getting-started)

[Swinject in practice](https://felginep.github.io/2019-02-05/swinject-in-practice)


