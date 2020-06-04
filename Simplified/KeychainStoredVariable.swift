//
//  KeychainStoredVariable.swift
//  SimplyE
//
//  Created by Jacek Szyja on 22/05/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

class KeychainVariable<VariableType> {
  let transaction: KeychainVariableTransaction
  var key: String {
    didSet {
      guard key != oldValue else { return }
      alreadyInited = false
    }
  }

  var alreadyInited = false
  var cachedValue: VariableType?

  init(key: String, accountInfoLock: NSRecursiveLock) {
    self.key = key
    self.transaction = KeychainVariableTransaction(accountInfoLock: accountInfoLock)
  }

  func read() -> VariableType? {
    guard !alreadyInited else { return cachedValue }
    cachedValue = NYPLKeychain.shared()?.object(forKey: key) as? VariableType
    alreadyInited = true
    return cachedValue
  }

  func write(_ newValue: VariableType?) {
    cachedValue = newValue
    alreadyInited = true
    DispatchQueue.global(qos: .userInitiated).async { [key] in
      if let newValue = newValue {
        NYPLKeychain.shared()?.setObject(newValue, forKey: key)
      } else {
        NYPLKeychain.shared()?.removeObject(forKey: key)
      }
    }
  }

  func safeWrite(_ newValue: VariableType?) {
    transaction.perform {
      write(newValue)
    }
  }
}

class KeychainCodableVariable<VariableType: Codable> {
  let transaction: KeychainVariableTransaction
  var key: String {
    didSet {
      guard key != oldValue else { return }
      alreadyInited = false
    }
  }

  var alreadyInited = false
  var cachedValue: VariableType?

  init(key: String, accountInfoLock: NSRecursiveLock) {
    self.key = key
    self.transaction = KeychainVariableTransaction(accountInfoLock: accountInfoLock)
  }

  func read() -> VariableType? {
    guard !alreadyInited else { return cachedValue }
    guard let data = NYPLKeychain.shared()?.object(forKey: key) as? Data else { cachedValue = nil; alreadyInited = true; return nil }
    cachedValue = try? JSONDecoder().decode(VariableType.self, from: data)
    alreadyInited = true
    return cachedValue
  }

  func write(_ newValue: VariableType?) {
    cachedValue = newValue
    alreadyInited = true
    DispatchQueue.global(qos: .userInitiated).async { [key] in
      if let newValue = newValue, let data = try? JSONEncoder().encode(newValue) {
        NYPLKeychain.shared()?.setObject(data, forKey: key)
      } else {
        NYPLKeychain.shared()?.removeObject(forKey: key)
      }
    }
  }

  func safeWrite(_ newValue: VariableType?) {
    transaction.perform {
      write(newValue)
    }
  }
}

class KeychainVariableTransaction {
  let accountInfoLock: NSRecursiveLock

  init(accountInfoLock: NSRecursiveLock) {
    self.accountInfoLock = accountInfoLock
  }

  func perform(operations: () -> Void) {
    guard NYPLKeychain.shared() != nil else { return }

    accountInfoLock.lock()
    defer {
      accountInfoLock.unlock()
    }

    operations()
  }
}
