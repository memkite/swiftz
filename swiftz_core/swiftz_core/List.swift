//
//  List.swift
//  swiftz_core
//
//  Created by Maxwell Swadling on 3/06/2014.
//  Copyright (c) 2014 Maxwell Swadling. All rights reserved.
//

import Foundation

public enum List<A> {
  case Nil
  case Cons(A, Box<List<A>>)
  
  public init() {
    self = .Nil
  }
    
  public init(_ head : A, _ tail : List<A>) {
    self = .Cons(head, Box(tail))
  }
  
  public func head() -> A? {
    switch self {
    case .Nil:
      return nil
    case let .Cons(head, _):
      return head
    }
  }
  
  public func tail() -> List<A>? {
    switch self {
    case .Nil:
      return nil
    case let .Cons(_, tail):
      return tail.value
    }
  }
  
  public func length() -> Int {
    switch self {
    case .Nil: return 0
    case let .Cons(_, xs): return 1 + xs.value.length()
    }
  }
  
  public func find(pred: A -> Bool) -> A? {
    for x in self {
      if pred(x) {
        return x
      }
    }
    return nil
  }
  public func lookup<K: Equatable, V>(ev: A -> (K, V), key: K) -> V? {
    func pred(t: (K, V)) -> Bool {
      return t.0 == key
    }
    func val(t: (K, V)) -> V {
      return t.1
    }
    return (({ val(ev($0)) }) <^> self.find({ pred(ev($0)) }))
  }
}

@infix public func ==<A : Equatable>(lhs : List<A>, rhs : List<A>) -> Bool {
  switch (lhs, rhs) {
  case (.Nil, .Nil):
    return true
  case let (.Cons(lHead, lTail), .Cons(rHead, rTail)):
    return lHead == rHead && lTail.value == rTail.value
  default:
    return false
  }
}

extension List : ArrayLiteralConvertible {
  static public func fromSeq<S : Sequence where S.GeneratorType.Element == A>(s : S) -> List<A> {
    // For some reason, everything simpler seems to crash the compiler
    var xs : [A] = []
    var g = s.generate()
    while let x : A = g.next() {
      xs += x
    }
    var l = List()
    for x in xs.reverse() {
      l = List(x, l)
    }
    return l
  }
  
  public static func convertFromArrayLiteral(elements: A...) -> List<A> {
    return fromSeq(elements)
  }
}


public class ListGenerator<A> : Generator {
  var l : Box<List<A>?>
  public func next() -> A? {
    var r = l.value?.head()
    l = Box(self.l.value?.tail())
    return r
  }
  public init(_ l : List<A>) {
    self.l = Box(l)
  }
}

extension List : Sequence {
  public func generate() -> ListGenerator<A> {
    return ListGenerator(self)
  }
}

extension List : Printable {
  public var description : String {
  var x = ", ".join(ListF(l: self).fmap({ "\($0)" }))
    return "[\(x)]"
  }
}

public struct ListF<A, B> : Functor {
  public let l : List<A>
    
  public init(l: List<A>) {
    self.l = l
  }
    
  // is recursion ok here?
  public func fmap(fn : (A -> B)) -> List<B> {
    switch l {
    case .Nil:
      return List()
    case let .Cons(head, tail):
      return List(fn(head), ListF(l: tail.value).fmap(fn))
    }
  }
}
