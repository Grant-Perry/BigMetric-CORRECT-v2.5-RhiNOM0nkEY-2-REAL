//
//  Atomic.swift
//  howFar Watch App
//
//  Created by Grant Perry on 4/17/23.
//

import Foundation

@propertyWrapper
struct Atomic<Value> {
   private var value: Value
   private let lock = NSLock()

   init(wrappedValue value: Value) {
      self.value = value
   }

   var wrappedValue: Value {
      get {
         lock.lock()
         defer { lock.unlock() }
         return value
      }
      set {
         lock.lock()
         defer { lock.unlock() }
         value = newValue
      }
   }
}
