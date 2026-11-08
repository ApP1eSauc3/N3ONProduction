//
//  AppLog.swift
//  N3ON — Tools layer
//
// Unified logging instead of print(). Dynamic values are logged with
// `privacy: .private`, so release builds redact them in Console/sysdiagnose —
// errors from DataStore/Auth can carry user data, and logs must not
// (OWASP MASVS-STORAGE: no sensitive data in logs).

import os

enum AppLog {
    static let app = Logger(subsystem: "NEON-CO.N3ON", category: "app")
}
