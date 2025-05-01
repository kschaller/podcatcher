//
//  AsynchronousOperation.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/25/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//
//  Inspired by Vasily Ulianov at https://gist.github.com/Sorix/57bc3295dc001434fe08acbb053ed2bc
//

import Foundation

/// Subclass of `Operation` that adds support for asynchronicity.
/// ## How to use:
/// - Call `super.main()` when overriding `main` method.
/// - Call `super.start()` when overriding `start` method.
/// - When the operation is finished or cancelled, set `self.state = .finished`.
class AsynchronousOperation: Operation {
    
    enum State: String {
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        fileprivate var keyPath: String { return "is\(self.rawValue)" }
    }
    
    override var isAsynchronous: Bool { return true }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
    
    var state = State.ready {
        willSet {
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }
        didSet {
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    override func start() {
        if isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }
    
    override func main() {
        if self.isCancelled {
            state = .finished
        } else {
            state = .executing
        }
    }

}
