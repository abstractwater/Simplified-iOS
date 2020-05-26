//
//  NYPLUserAccountFrontEndValidation.swift
//  SimplyE
//
//  Created by Jacek Szyja on 26/05/2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

import UIKit

/**
 Protocol that represents the input sources / UI requirements for performing
 front-end validation.
 */
@objc
protocol NYPLUserAccountInputProvider {
  var usernameTextField: UITextField! { get set }
  var PINTextField: UITextField! { get set }
}

@objcMembers class NYPLUserAccountFrontEndValidation: NSObject {
  let userInputProvider: NYPLUserAccountInputProvider
  let account: Account
  let selectedAuthentication: AccountDetails.Authentication

  init(account: Account, selectedAuthentication: AccountDetails.Authentication, inputProvider: NYPLUserAccountInputProvider) {
    self.userInputProvider = inputProvider
    self.account = account
    self.selectedAuthentication = selectedAuthentication
  }
}

extension NYPLUserAccountFrontEndValidation: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return !NYPLUserAccount.sharedAccount().hasBarcodeAndPIN()
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard string.canBeConverted(to: .ascii) else { return false }

    if textField == userInputProvider.usernameTextField,
      selectedAuthentication.patronIDKeyboard != .email {

      // Barcodes are numeric and usernames are alphanumeric including punctuation
      let allowedCharacters = CharacterSet.alphanumerics.union(.punctuationCharacters)
      let bannedCharacters = allowedCharacters.inverted

      guard string.rangeOfCharacter(from: bannedCharacters) == nil else { return false }

      if let text = textField.text,
        let textRange = Range(range, in: text) {

        let updatedText = text.replacingCharacters(in: textRange, with: string)
        guard updatedText.count <= 25 else { return false }
      }
    }

    if textField == userInputProvider.PINTextField {
      let allowedCharacters = CharacterSet.decimalDigits
      let bannedCharacters = allowedCharacters.inverted

      let alphanumericPin = selectedAuthentication.pinKeyboard != .numeric
      let containsNonNumeric = !(string.rangeOfCharacter(from: bannedCharacters)?.isEmpty ?? true)
      let abovePinCharLimit: Bool

      if let text = textField.text,
        let textRange = Range(range, in: text) {

        let updatedText = text.replacingCharacters(in: textRange, with: string)
        abovePinCharLimit = updatedText.count > selectedAuthentication.authPasscodeLength
      } else {
        abovePinCharLimit = false
      }

      // PIN's support numeric or alphanumeric.
      guard alphanumericPin || !containsNonNumeric else { return false }

      // PIN's character limit. Zero is unlimited.
      if selectedAuthentication.authPasscodeLength == 0 {
        return true
      } else if abovePinCharLimit {
        return false
      }
    }

    return true
  }
}
