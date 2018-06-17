//
//  AsynchronousOperation.swift
//  Podcatcher
//
//  Created by Kai Schaller on 5/25/18.
//  Copyright © 2018 Kai Schaller. All rights reserved.
//

import Foundation

class AsynchronousOperation: Operation {
    
    private let stateQueue = DispatchQueue(label: "com.kaischaller.operation.state", attributes: .concurrent)
    
    private var rawState = OperationState.ready
    
    private var state: OperationState {
        get {
            return stateQueue.sync(execute: { rawState })
        }
        set {
            willChangeValue(forKey: "state")
            stateQueue.sync(flags: .barrier, execute: { rawState = newValue })
            didChangeValue(forKey: "state")
        }
    }
    
    final override var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    final override var isExecuting: Bool {
        return state == .executing
    }
    
    final override var isFinished: Bool {
        return state == .finished
    }
    
    final override var isAsynchronous: Bool {
        return true
    }
    
}

private enum OperationState: Int {
    case ready
    case executing
    case finished
}
