# ARC in Swift : Basics and beyond

이번 세션 또한 굉장히 중요한 세션이라고 할 수 있습니다. iOS에서는 메모리 관리를 위해서 ARC라는 기법을 사용합니다. Automatic Reference Counting의 약자로 자동으로 객체의 사용을 추적하여 더 이상 사용되지 않는 경우 메모리에서 해제하는 기법입니다. 이번에 Xcode 13의 ARC 최적화에서 어떻게 변경이 되었는지 그리고 어떤 사이드 이펙트가 생길 가능성이 있는지 확인해보겠습니다.



# Basic

Swift에서는 값에 대한 타입으로 Reference Type 그리고 Value Type을 사용할 수 있으며 웬만하면 value Type을 사용하는 것을 추천합니다. 이유는 Reference Type을 사용하는 경우 상황에 따라서 의도치 않은 공유가 될 수 있기 때문입니다. 이때 말하는 Reference Type은 대표적으로 Closure, Class instance 등이 있습니다. 이러한 Reference Type은 ARC를 통해서 관리됩니다. 따라서 Swift를 제대로 활용하기 위해서는 ARC를 제대로 이해하는 것이 중요합니다.







