import Foundation
import CryptoKit

nonisolated struct EncryptionService: Sendable {
    static let shared = EncryptionService()

    func encrypt(_ plaintext: String, key: SymmetricKey) throws -> Data {
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else { throw NSError(domain: "encrypt", code: 0) }
        return combined
    }

    func decrypt(_ data: Data, key: SymmetricKey) throws -> String {
        let box = try AES.GCM.SealedBox(combined: data)
        let decrypted = try AES.GCM.open(box, using: key)
        return String(decoding: decrypted, as: UTF8.self)
    }

    func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
}
