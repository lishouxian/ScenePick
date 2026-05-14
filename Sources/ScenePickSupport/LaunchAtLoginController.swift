import Combine
import Foundation
import ServiceManagement

@MainActor
public final class LaunchAtLoginController: ObservableObject {
    @Published public private(set) var status: LaunchAtLoginStatus
    @Published public private(set) var isUpdating = false
    @Published public private(set) var errorMessage: String?

    private let service: any LoginItemServicing

    public init(service: any LoginItemServicing = SMAppLoginItemService()) {
        self.service = service
        self.status = service.status
    }

    public var isEnabled: Bool {
        status == .enabled
    }

    public func refresh() {
        errorMessage = nil
        refreshStatus()
    }

    public func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else {
            refresh()
            return
        }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        refreshStatus()
    }

    private func refreshStatus() {
        status = service.status
    }
}

@MainActor
public protocol LoginItemServicing {
    var status: LaunchAtLoginStatus { get }
    func register() throws
    func unregister() throws
}

public struct SMAppLoginItemService: LoginItemServicing {
    private let service: SMAppService

    public init(service: SMAppService = .mainApp) {
        self.service = service
    }

    public var status: LaunchAtLoginStatus {
        LaunchAtLoginStatus(service.status)
    }

    public func register() throws {
        try service.register()
    }

    public func unregister() throws {
        try service.unregister()
    }
}

public enum LaunchAtLoginStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable

    public init(_ status: SMAppService.Status) {
        switch status {
        case .enabled:
            self = .enabled
        case .notRegistered:
            self = .disabled
        case .requiresApproval:
            self = .requiresApproval
        case .notFound:
            self = .unavailable
        @unknown default:
            self = .unavailable
        }
    }
}
