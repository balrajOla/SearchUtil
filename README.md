# SearchUtil
This utility class provide a generic interface to perform search operation with following features:-
  1. Throttling keystroke with timeinterval
  2. Perform pre execution operation
  3. Cancelling older request
  4. Return a response with the keyword that it was searched for  

## Initialization
```swift
init(throttle: TimeInterval,
     minimumKeywordCount: Int,
     preExecutionOperation: @escaping () -> Void,
     query: @escaping (String?) -> Promise<R>,
     completion: @escaping ((keyword: String, result: Result<R>)) -> Void)
```
     
## Search
```swift
search(keyword: String)
```

## Dependencies
```swift
import PromiseKit
import RxSwift
```
     


