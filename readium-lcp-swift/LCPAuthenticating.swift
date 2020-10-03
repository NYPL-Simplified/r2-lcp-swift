//
//  Copyright 2020 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation

public protocol LCPAuthenticating {

    /// Requests a passphrase to decrypt the given license.
    ///
    /// The reading app can prompt the user to enter the passphrase, or retrieve it by any other
    /// means (eg. web service).
    ///
    /// - Parameters:
    ///   - license: Information to show to the user about the license being opened.
    ///   - reason: Reason why the passphrase is requested. It should be used to prompt the user.
    ///   - allowUserInteraction: Indicates whether the user can be prompted for their passphrase.
    ///     If your implementation requires it and `allowUserInteraction` is false, terminate
    ///     quickly by sending `nil` to the completion block.
    ///   - sender: Free object that can be used by reading apps to give some UX context when
    ///     presenting dialogs. For example, the host `UIViewController`.
    ///   - completion: Used to return the retrieved passphrase. If the user cancelled, send nil.
    ///     The passphrase may be already hashed.
    func requestPassphrase(for license: LCPAuthenticatedLicense, reason: LCPAuthenticationReason, allowUserInteraction: Bool, sender: Any?, completion: @escaping (String?) -> Void)
    
}

public enum LCPAuthenticationReason {
    /// No matching passphrase was found.
    case passphraseNotFound
    /// The provided passphrase was invalid.
    case invalidPassphrase
}

public struct LCPAuthenticatedLicense {

    /// A hint to be displayed to the User to help them remember the User Passphrase.
    public var hint: String {
        return document.encryption.userKey.textHint
    }
    
    /// Location where a Reading System can redirect a User looking for additional information about the User Passphrase.
    public var hintLink: Link? {
        return document.link(for: .hint)
    }
    
    /// Support resources for the user (either a website, an email or a telephone number).
    public var supportLinks: [Link] {
        return document.links(for: .support)
    }
    
    /// URI of the license provider.
    public var provider: String {
        return document.provider
    }
    
    /// Informations about the user owning the license.
    public var user: User? {
        return document.user
    }

    /// License Document being opened.
    public let document: LicenseDocument

    init(document: LicenseDocument) {
        self.document = document
    }

}

/// An `LCPAuthenticating` implementation which can directly use a provided clear or hashed
/// passphrase.
///
/// If the provided `passphrase` is incorrect, the given `fallback` authentication is used.
public class LCPPassphrase: LCPAuthenticating {
    
    private let passphrase: String
    private let fallback: LCPAuthenticating?
    
    public init(_ passphrase: String, fallback: LCPAuthenticating? = nil) {
        self.passphrase = passphrase
        self.fallback = fallback
    }
    
    public func requestPassphrase(for license: LCPAuthenticatedLicense, reason: LCPAuthenticationReason, allowUserInteraction: Bool, sender: Any?, completion: @escaping (String?) -> Void) {
        guard reason == .passphraseNotFound else {
            if let fallback = fallback {
                fallback.requestPassphrase(for: license, reason: reason, allowUserInteraction: allowUserInteraction, sender: sender, completion: completion)
            } else {
                completion(nil)
            }
            return
        }
        
        completion(passphrase)
    }
    
}
