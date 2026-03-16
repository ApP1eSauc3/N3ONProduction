//
//  Tools/ViewExtensions.swift
//
//  Cross-version SwiftUI modifiers.
//
//  onChange changed between iOS 16 and 17:
//    iOS 16:  .onChange(of: v) { newVal in }         ← 1 param, current API
//    iOS 17:  .onChange(of: v) { old, new in }        ← 2 params, preferred
//             .onChange(of: v) { }                   ← 0 params, new
//             deprecated the 1-param form with a warning
//
//  onChangeCompat picks the right form at compile time via #available.
//  Source: https://useyourloaf.com/blog/swiftui-onchange-deprecation/
//

import SwiftUI

extension View {

    /// onChange backport — provides old + new value on iOS 16 and 17+.
    @ViewBuilder
    func onChangeCompat<V: Equatable>(
        of value: V,
        perform action: @escaping (_ old: V, _ new: V) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value, action)
        } else {
            self.onChange(of: value) { [value] newValue in
                action(value, newValue)
            }
        }
    }

    /// Zero-parameter variant — when you only need to react, not read the value.
    @ViewBuilder
    func onChangeCompat<V: Equatable>(
        of value: V,
        perform action: @escaping () -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { action() }
        } else {
            self.onChange(of: value) { _ in action() }
        }
    }
}
