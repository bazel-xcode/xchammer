// Copyright 2018-present, Pinterest, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
