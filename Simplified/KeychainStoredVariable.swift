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
  var key: String

  init(key: String, accountInfoLock: NSRecursiveLock) {
    self.key = key
    self.transaction = KeychainVariableTransaction(accountInfoLock: accountInfoLock)
  }

  func read() -> VariableType? {
    return NYPLKeychain.shared()?.object(forKey: key) as? VariableType
  }

  func write(_ newValue: VariableType?) {
    if let newValue = newValue {
      NYPLKeychain.shared()?.setObject(newValue, forKey: key)
    } else {
      NYPLKeychain.shared()?.removeObject(forKey: key)
    }
  }

  func safeWrite(_ newValue: VariableType?) {
    transaction.write {
      write(newValue)
    }
  }
}

class KeychainVariableTransaction {
  let accountInfoLock: NSRecursiveLock

  init(accountInfoLock: NSRecursiveLock) {
    self.accountInfoLock = accountInfoLock
  }

  func write(transaction: () -> Void) {
    guard NYPLKeychain.shared() != nil else { return }

    accountInfoLock.lock()
    defer {
      accountInfoLock.unlock()
    }

    transaction()
  }
}
