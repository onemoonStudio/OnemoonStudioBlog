# UINib Basic

이직을 하면서 처음에 가장 어려움을 겪었던 부분이 Storyboard 기반으로 UI를 작성하는 일이었습니다. UI를 그리는 자체는 어렵지 않았으나, 생성되는 시점이 기존에 사용하던 CodeBase와는 너무 달랐기 때문이었습니다. 이에 대해서 정리를 해야겠다고 생각을 했고, 생성 시점, File's owner 등등 여러가지 주제를 다룰 생각입니다. 하지만 제일 먼저 UINib에 대해서 명확하게 아는 것이 중요하다고 생각하여 오늘은 UINib에 대해서 정리를 해볼 생각입니다.

## UINib

>  An object that contains Interface Builder nib files. 

먼저 [문서](https://developer.apple.com/documentation/uikit/uinib/)를 기반으로 몇가지를 살펴보겠습니다. 정의를 살펴보면 Interface Builder nib files 들을 갖고 있는 객체라고 합니다. 첫번째로 한개가 아닌 여러개의 nib files 라는 것을 알 수 있습니다. 조금 더 읽어보겠습니다.



UINib은 nib file 콘텐츠를 caching 하고 있으며, unarchiving 그리고 instantiation 을 위한 준비를 합니다. 만약 nib의 콘텐츠가 필요한 경우 data를 로드할 필요 없이 부를 수 있기 때문에 성능측면에서 좋습니다. 만약 메모리가 부족한 경우 메모리에 있는 캐시된 nib 파일을 날립니다. 그리고 다음에 필요한 경우 nib을 생성합니다. ( 캐시된 데이터가 날라갔으므로 다시 data를 로드해서 부른다는 말 ) 

만약 반복적으로 instantiate가 필요한 경우 UINib을 사용해야 합니다. 왜냐면 이미 UINib에 대한 contents가 캐싱 되었기 때문에 이는 성능에 대한 향상으로 이뤄질 수 있습니다. 

만약 nibfile의 contents를 사용해서 UINib 객체를 생성했다면, 해당 객체는 object graph에 있는 nib file reference를 통해서 생성한 것이지만, unarchiving이 제대로 되지 않은것 입니다. nib data를 모두 unarchive하기 위해서 instatiate(withOwner:options:)를 호출해야 합니다. UINib Object와 nib's object graph 에대한 자세한 내용은 [Resource Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Introduction/Introduction.html#//apple_ref/doc/uid/10000051i) 를 살펴보시면 됩니다.



간단하게 알아보려 했으나 새로운 내용들이 자꾸만 나오는군요. archive 그리고 unarchive라는 개념, nib file 의 caching, 그리고 resource programming guide 까지 알아야 할 부분들이 참 많은 것 같습니다. Resource Programming Guide 를 먼저 읽어야 조금 수월하게 읽힐 것 같은 느낌이지만, 일단 지금은 나와있는 init 그리고 위에서 언급된 instantiate 를 한번 살펴보겠습니다.



## UINib init

### init(nibName:bundle:)

> Returns a nib object from the nib file in the specified bundle.

특정한 번들로부터 nib file을 리턴한다고 합니다. name 인자는 따라서 nibfile의 이름이 될 것이고, bundle은 특정한 bundle이 되겠군요. 여기서 Bundle의 경우 Optional로 되어 있습니다. 이 경우에는 main bundle에서 nib file을 자동으로 찾는다고 합니다. ( bundle의 정확한 개념도 한번 공부해야봐야 겠습니다 ㅠㅠ )

file의 위치를 찾지 못하는 경우 error를 던지는 것을 확인할 수 있습니다. 

### init(data:bundle:)

> Creates a nib object from nib data stored in memory.

메모리에 있는 저장된 Nib data로부터 객체를 생성합니다. 위의 initializer와 마찬가지로 data를 찾지 못하는 경우에 error를 던지는 것을 확인할 수 있습니다. 동일한 듯 보이지만 사실상 애플에서는 상단에 있는 nibName을 통해서 UINib 객체를 생성하는 것을 선호한다고 합니다. 그 이유는 위에서 잠깐 언급했듯이 low memory 인 경우에서 memory에 있는 캐시된 nib data 는 release 될 수 있다고 했는데요, 만약 init(data:bundle:)을 사용한다면 해당 데이터는 release 되지 않는 특성이 있다고 합니다. 그러므로 상황에 따라서 memory를 관리할 수 있도록 하는 nibName을 통해서 init을 하라고 말하는 것 같습니다.



두 이니셜라이저 모두 bundle에 있는 language-specific한 directories를 먼저 찾으며, 그 이후 Resources directory 에 있는 nib file을 찾습니다. 



## instance Method

그렇다면 위와 같은 과정을 통해서 UINib 객체를 만들었을 때 사용하는 메서드를 살펴보겠습니다. instantiate(withOwner:options:) 입니다.

### instantiate(withOwner:options:)

> Unarchives and instantiates the in-memory contents of the nib object’s nib file, creating a distinct object tree and set of top-level objects. >  메모리에 있는 nib data를 unarchive 하고 instantiates 하여, 고유한 객체 트리와 최상위 레벨 집합을 만듭니다. 

말이 조금 어렵네요. 제가 생각하기에는 메모리상에는 캐싱된 데이터가 있으며 이를 통해 내부에 있는 nib files를 만들 수 있는데, instantiate 를 해서 공유되지 않은 고유한 객체들을 만든다고 이해하면 될 것 같습니다. 따라서 UINib만 만들어 사용하면 되는 것이 아니라 instantiate를 통해서 우리가 사용할 수 있게끔 따로 객체를 만들어야 하는 것으로 이해할 수 있습니다.

두개의 파라미터에 대해서 살펴보자면 먼저 첫번째 파라미터 withOwner 자리에 들어가는 ownerOfNil: Any? 가 있습니다. nib file의 owner(file's Owner)로 사용하는 객체를 넣어야 합니다. 만약 nib file이 owner 가 있다면, 반드시 유효한 값의 객체 (owner) 를 넣어야 합니다. 

생각해보니 우리가 nib을 만들고 이를 사용하기 위해서는 두가지 방식이 있습니다. 첫번째로 file's Owner를 사용하는 방법, 두번째로 Custom Class를 사용하는 방법입니다. 이때 첫번째 file's Owner 방식으로 Nib을 사용하고 싶다면 반드시 owner 에 유효한 객체를 넣어야 함을 이해할 수 있겠군요!

그 다음 두번째 파라미터 optionsOrNil: [UINib.OptionsKey : Any]? 가 있네요. nibfile을 열때 사용하는 옵션이라고 이해할 수 있겠습니다. 살펴보니 externalObjects라는 하나의 키를 갖고 있네요. nib 파일이 외부의 객체를 참조하게 되는 경우 외부 객체는 해당 키를 통해서 전달이 되어야 한다고 합니다. ( 자료가 많이 없어 궁금하신 분들은 하단의 마지막 2개 링크 참고하시길 바랍니다. )

이런 파라미터를 통해서 리턴되는 값은 autoreleased 된 NSArray 로써 nib file에 있는 최상위 객체들을 포함하고 있습니다.

해당 메서드를 통해서 nib에 있는 객체를 제공할 수 있습니다. 해당 메서드를 통해서 각각의 객체를 unarchives하며 initialize하고 각각의 객체와 connection을 다시 합니다. 자세한 내용은 Resource Programming Guide를 살펴보시길 바랍니다. 만약 nib file 이 단순히 File's Owner를 넘어서 proxy objects 를 포함하고 있다면, option을 통해 런타임시에 변경될 object를 명시할 수 있습니다. 

## 마무리

먼저 간단하게 UINib의 문서에 있는 내용들을 살펴 보았습니다. 사실 init(coder) 와 archiving 등을 알아보고 싶었는데, UINib만해도 알아볼 내용이 산더미인 것을 실감하였습니다 ^^... 다음에는 여기에서 살펴보지 못한 Bundle, nib 파일에 있는 객체를 사용하는 두가지 방식 ( file's owner , custom class ) , init coder 그리고 Resource Programming Guide 등을 살펴볼 예정입니다! 





### Reference

https://developer.apple.com/documentation/uikit/uinib/

https://www.indelible.org/ink/nib-loading/

https://coderedirect.com/questions/369715/how-to-use-a-common-target-object-to-handle-actions-outlets-of-multiple-views