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

infix operator <>: AdditionPrecedence
infix operator <>=: AssignmentPrecedence

/// https://en.wikipedia.org/wiki/Semigroup
protocol Semigroup {
    static func <>(lhs: Self, rhs: Self) -> Self
}
extension Semigroup {
    static func <>=(lhs: inout Self, rhs: Self) {
        lhs = lhs <> rhs
    }
}
func <>=<A: Semigroup>(lhs: inout A?, rhs: A?) {
    lhs = lhs <> rhs
}

/// https://en.wikipedia.org/wiki/Monoid
protocol Monoid: Semigroup {
    static var empty: Self { get }
}

/// Possible transitions during traversals
/// Transitions form a monoid
///
/// The combining operation prefers the "stoppier" transition among the two.
/// Stop trumps all, justOnceMore trumps keepGoing
/// This makes our identity the keepGoing
enum Transition: Monoid {
    case stop
    case justOnceMore
    case keepGoing
    
    static var empty: Transition {
        return .keepGoing
    }
    
    static func <>(lhs: Transition, rhs: Transition) -> Transition {
        switch (lhs, rhs) {
        case (.stop, _), (_, .stop):
            return .stop
        case (.justOnceMore, _):
            return .justOnceMore
        case let (.keepGoing, other):
            return other
        }
    }
}

/// All functions into monoids form a monoid
struct FunctionM<A, M: Monoid>: Monoid {
    let run: (A) -> M
    
    static var empty: FunctionM {
        return FunctionM { _ in M.empty }
    }
    
    static func <>(lhs: FunctionM, rhs: FunctionM) -> FunctionM {
        return FunctionM{ a in lhs.run(a) <> rhs.run(a) }
    }
}

/// A TraversalTransitionPredicate<T> describes what to do during a transation between nodes
/// of type T during a traversal of some kind.
typealias TraversalTransitionPredicate<T> = FunctionM<T, Transition>

func <><A: Semigroup>(lhs: A?, rhs: A?) -> A? {
    switch (lhs, rhs) {
    case (.none, .none):
        return .none
    case let (.some(l), .none):
        return .some(l)
    case let (.none, .some(r)):
        return .some(r)
    case let (.some(l), .some(r)):
        return .some(l<>r)
    }
}

struct First<T>: Semigroup {
    let v: T
    init(_ v: T) { self.v = v }
    
    static func <>(lhs: First, rhs: First) -> First {
        return lhs
    }
}

extension String: Monoid {
    static var empty: String {
        return ""
    }
    
    static func <>(lhs: String, rhs: String) -> String {
        return lhs + rhs
    }
}

extension Array: Monoid {
    static var empty: Array {
        return []
    }
    
    static func <>(lhs: Array, rhs: Array) -> Array {
        return lhs + rhs
    }
}

extension Set: Monoid {
    static var empty: Set {
        return []
    }
    
    static func <>(lhs: Set, rhs: Set) -> Set {
        return lhs.union(rhs)
    }
}

extension Sequence {
    func foldMap<M: Monoid>(_ f: (Element) -> M) -> M {
        var m = M.empty
        for x in self {
            m = m <> f(x)
        }
        return m
    }
}
