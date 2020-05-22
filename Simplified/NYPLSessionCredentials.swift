//
//  NYPLSessionCredentials.swift
//  SimplyE
//
//  Created by Jacek Szyja on 22/05/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import Foundation

enum Credentials {
//  case token(authToken: String, patron: [String:Any])
  case token(authToken: String)
  case barcodeAndPin(barcode: String, pin: String)
  case open
}

extension Credentials: Codable {
  enum TypeID: Int, Codable {
    case token
    case barcodeAndPin
    case open
  }

  private var typeID: TypeID {
    switch self {
    case .token: return .token
    case .barcodeAndPin: return .barcodeAndPin
    case .open: return .open
    }
  }

  enum CodingKeys: String, CodingKey {
    case type
    case associatedTokenData
    case associatedBarcodeAndPinData
  }

  enum TokenKeys: String, CodingKey {
    case authToken
    case patron
  }

  enum BarcodeAndPinKeys: String, CodingKey {
    case barcode
    case pin
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let type = try values.decode(TypeID.self, forKey: .type)

    switch type {
    case .token:
      let additionalInfo = try values.nestedContainer(keyedBy: TokenKeys.self, forKey: .associatedTokenData)
      let token = try additionalInfo.decode(String.self, forKey: .authToken)
//      let patronData = try additionalInfo.decode(Data.self, forKey: .patron)
//      guard let patron = try JSONSerialization.jsonObject(with: patronData, options: .allowFragments) as? [String: Any] else {
//        throw NSError()
//      }
//      self = .token(authToken: token, patron: patron)
      self = .token(authToken: token)

    case .barcodeAndPin:
      let additionalInfo = try values.nestedContainer(keyedBy: BarcodeAndPinKeys.self, forKey: .associatedBarcodeAndPinData)
      let barcode = try additionalInfo.decode(String.self, forKey: .barcode)
      let pin = try additionalInfo.decode(String.self, forKey: .pin)
      self = .barcodeAndPin(barcode: barcode, pin: pin)

    case .open: self = .open
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(typeID, forKey: .type)

    switch self {
//    case let .token(authToken: token, patron: info):
    case let .token(authToken: token):
      var additionalInfo = container.nestedContainer(keyedBy: TokenKeys.self, forKey: .associatedTokenData)
      try additionalInfo.encode(token, forKey: .authToken)
//      let data = try JSONSerialization.data(withJSONObject: info, options: [])
//      try additionalInfo.encode(data, forKey: .patron)

    case let .barcodeAndPin(barcode: barcode, pin: pin):
      var additionalInfo = container.nestedContainer(keyedBy: BarcodeAndPinKeys.self, forKey: .associatedBarcodeAndPinData)
      try additionalInfo.encode(barcode, forKey: .barcode)
      try additionalInfo.encode(pin, forKey: .pin)

    default: break
    }
  }
}

extension String {
  func asKeychainVariable<VariableType>(with accountInfoLock: NSRecursiveLock) -> KeychainVariable<VariableType> {
    return KeychainVariable<VariableType>(key: self, accountInfoLock: accountInfoLock)
  }
}
