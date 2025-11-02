import Foundation

/// Centralized helpers for binding Optional<String> in SwiftUI inputs.
/// Use `someOptional.bound` to read/write as a non-optional string, where empty writes back as nil.
/// Use `someOptional.orEmpty()` to read a non-optional string without mutating.
extension Optional where Wrapped == String {
    /// Read/write binding: returns empty string when nil; writes empty string back as nil.
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }

    /// Non-mutating convenience to read as a non-optional string.
    func orEmpty() -> String {
        return self ?? ""
    }
}
