//
//  SearchUtility.swift
//  SearchUtility
//
//  Created by Balraj Singh on 07/03/18.
//  Copyright © 2018 balraj. All rights reserved.
//

import Foundation
import PromiseKit
import RxSwift

public enum SearchError : Error {
    case internalError
}

public struct SearchUtility<R> {
    
    private var throttle: TimeInterval
    private var minimumKeywordCount: Int
    private var preExecutionOperation : () -> Void
    private var query: (String?) -> Promise<R>
    private var completion: ((keyword: String, result: Result<R>)) -> Void
    
    private let dataSource = Variable<String>("")
    
    private let disposeBag = DisposeBag()
    
    private let DEFAULT_THROTTLE_TIME = 0.5
    
    public init(throttle: TimeInterval,
                minimumKeywordCount: Int,
                preExecutionOperation: @escaping () -> Void,
                query: @escaping (String?) -> Promise<R>,
                completion: @escaping ((keyword: String, result: Result<R>)) -> Void) {
        self.throttle = throttle
        self.minimumKeywordCount = minimumKeywordCount
        self.query = query
        self.completion = completion
        self.preExecutionOperation = preExecutionOperation
        
        setUpSearchStream()
    }
    
    // perform search operation
    public func search(keyword: String) {
        self.dataSource.value = keyword
    }
    
    // This method created a data stream to perform certain actions based on prerequisite
    private func setUpSearchStream() {
        self.dataSource.asObservable()
            .debounce(self.throttle, scheduler: MainScheduler.instance) // throttle
            .do(onNext: { _ in  self.preExecutionOperation()}) // clear text
            .flatMapLatest { keyword -> Observable<(keyword: String, result: Result<R>)> in       // per request and ignore the previous request
                return Observable.create { observer in
                    // execute query only if minimum number of keywork count exceeds
                    if self.minimumKeywordCountCheck(keyword: keyword) {
                        // listen to query
                        self.query(keyword)
                            .tap(execute: { (result) in
                                observer.onNext((keyword: keyword, result: result))
                            })
                    } else {
                        observer.onCompleted()
                    }
                    
                    // disposing the previous request
                    return Disposables.create {
                        observer.onCompleted()
                    }
                    }.observeOn(MainScheduler.instance)
            }.subscribe({ (responseEvent) in
                
                guard let result = responseEvent.element else {
                    // in case of some error consditions
                    self.completion((keyword: "", result: Result.rejected(SearchError.internalError)))
                    return
                }
                
                // if success return the result
                self.completion(result)
                
            }).disposed(by: disposeBag)
    }
    
    // condition to check minimum character count threshold
    private func minimumKeywordCountCheck(keyword: String) -> Bool {
        return keyword.count >= self.minimumKeywordCount
    }
}

