import Foundation

enum AudioBookVendors: String, CaseIterable {
  case cantook = "cantook"
}

enum NYPLSecrets {
  private static let salt: [UInt8] = [0]

  static var cardCreator:String? {
    #if !DEBUG
      #error("Secrets file not generated")
    #endif
    let encoded: [UInt8] = [0]
    return decode(encoded, cipher: salt)
  }
    
  static var cardCreatorInfo:[String:Any] {
    #if !DEBUG
      #error("Secrets file not generated")
    #endif
    return [:]
  }

  static func feedbookKeys(forVendor name: AudioBookVendors) -> String? {
    #if !DEBUG
      #error("Secrets file not generated")
    #endif
    let allKeys : [String: [UInt8]] = [:]
    guard let encoded = allKeys[name.rawValue] else { return nil }
    return decode(encoded, cipher: salt)
  }

  static func feedbookInfo(forVendor name: AudioBookVendors) -> [String:Any] {
    #if !DEBUG
      #error("Secrets file not generated")
    #endif
    let info : [String: [String:Any]] = [:]
    return info[name.rawValue] ?? [:]
  }

  private static func decode(_ encoded: [UInt8], cipher: [UInt8]) -> String? {
    #if !DEBUG
      #error("Secrets file not generated")
    #endif
    var decrypted = [UInt8]()
    return String(bytes: decrypted, encoding: .utf8)
  }
}
