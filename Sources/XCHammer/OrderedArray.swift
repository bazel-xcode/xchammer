//
//  OrderedArray.swift
//  XCHammer
//
//  Created by Brandon Kase on 12/11/17.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

import Foundation

struct OrderedArray<T: Hashable>: Sequence {
    typealias Element = T
    
    /// Invariant: Array has no duplicates
    private var arr: [Element]
    private var set: Set<Element>
    
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == Element {
        self.set = []
        self.arr = []
        
        self.appendAll(sequence)
    }
    
    func makeIterator() -> Array<Element>.Iterator {
        return arr.makeIterator()
    }
    
    mutating func append(_ member: Element) {
        if !set.contains(member) {
            set.insert(member)
            arr.append(member)
        }
    }
    
    mutating func appendAll<S: Sequence>(_ s: S) where S.Iterator.Element == Element {
        for x in s {
            append(x)
        }
    }
}

extension OrderedArray: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Element
    
    init(arrayLiteral elements: T...) {
        self.init(elements)
    }
}

extension OrderedArray: Semigroup {
    static func <>(lhs: OrderedArray, rhs: OrderedArray) -> OrderedArray {
        var mut = lhs
        mut.appendAll(rhs)
        return mut
    }
}

extension OrderedArray: Monoid {
    static var empty: OrderedArray { return OrderedArray() }
}
