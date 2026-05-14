import Foundation
import ScenePickSupport
import ServiceManagement
import Combine

@main
@MainActor
struct ScenePickLoginItemSelfTest {
    static func main() throws {
        try mapsSMAppServiceStatuses()
        try togglesOnWithFakeService()
        try togglesOffWithFakeService()
        try refreshesStatusAfterRegisterFailure()
        try doesNotTreatApprovalOrUnavailableAsEnabled()
        try repeatedRefreshWithoutStateChangeDoesNotPublishChanges()

        print("ScenePickLoginItemSelfTest: 6 tests passed")
    }

    private static func mapsSMAppServiceStatuses() throws {
        try expect(LaunchAtLoginStatus(.enabled) == .enabled, "enabled status mapping")
        try expect(LaunchAtLoginStatus(.notRegistered) == .disabled, "not registered status mapping")
        try expect(LaunchAtLoginStatus(.requiresApproval) == .requiresApproval, "requires approval status mapping")
        try expect(LaunchAtLoginStatus(.notFound) == .unavailable, "not found status mapping")
    }

    private static func togglesOnWithFakeService() throws {
        let service = FakeLoginItemService(initialStatus: .disabled)
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(true)

        try expect(service.registerCalls == 1, "register should be called once")
        try expect(service.unregisterCalls == 0, "unregister should not be called")
        try expect(controller.status == .enabled, "controller should refresh enabled status")
        try expect(controller.isEnabled, "controller should report enabled")
        try expect(controller.errorMessage == nil, "successful register should not show an error")
    }

    private static func togglesOffWithFakeService() throws {
        let service = FakeLoginItemService(initialStatus: .enabled)
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(false)

        try expect(service.unregisterCalls == 1, "unregister should be called once")
        try expect(service.registerCalls == 0, "register should not be called")
        try expect(controller.status == .disabled, "controller should refresh disabled status")
        try expect(!controller.isEnabled, "controller should report disabled")
    }

    private static func refreshesStatusAfterRegisterFailure() throws {
        let service = FakeLoginItemService(
            initialStatus: .disabled,
            statusAfterRegisterFailure: .requiresApproval,
            registerError: TestError.registerFailed
        )
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(true)

        try expect(service.registerCalls == 1, "register should be attempted once")
        try expect(controller.status == .requiresApproval, "controller should refresh status after register failure")
        try expect(!controller.isEnabled, "requires approval should not be enabled")
        try expect(controller.errorMessage == TestError.registerFailed.localizedDescription, "controller should expose raw register error")
    }

    private static func doesNotTreatApprovalOrUnavailableAsEnabled() throws {
        let approvalController = LaunchAtLoginController(
            service: FakeLoginItemService(initialStatus: .requiresApproval)
        )
        let unavailableController = LaunchAtLoginController(
            service: FakeLoginItemService(initialStatus: .unavailable)
        )

        try expect(!approvalController.isEnabled, "requires approval should not be treated as enabled")
        try expect(!unavailableController.isEnabled, "unavailable should not be treated as enabled")
    }

    private static func repeatedRefreshWithoutStateChangeDoesNotPublishChanges() throws {
        let service = FakeLoginItemService(initialStatus: .disabled)
        let controller = LaunchAtLoginController(service: service)
        var publishedChanges = 0
        let cancellable = controller.objectWillChange.sink {
            publishedChanges += 1
        }

        controller.refresh()
        controller.refresh()
        controller.refresh()

        cancellable.cancel()
        try expect(publishedChanges == 0, "refresh should not publish when status and error are unchanged")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw TestFailure(message)
        }
    }
}

@MainActor
private final class FakeLoginItemService: LoginItemServicing {
    private(set) var registerCalls = 0
    private(set) var unregisterCalls = 0
    private let statusAfterRegisterFailure: LaunchAtLoginStatus
    private let registerError: Error?

    var status: LaunchAtLoginStatus

    init(
        initialStatus: LaunchAtLoginStatus,
        statusAfterRegisterFailure: LaunchAtLoginStatus? = nil,
        registerError: Error? = nil
    ) {
        status = initialStatus
        self.statusAfterRegisterFailure = statusAfterRegisterFailure ?? initialStatus
        self.registerError = registerError
    }

    func register() throws {
        registerCalls += 1
        if let registerError {
            status = statusAfterRegisterFailure
            throw registerError
        }

        status = .enabled
    }

    func unregister() throws {
        unregisterCalls += 1
        status = .disabled
    }
}

private enum TestError: LocalizedError {
    case registerFailed

    var errorDescription: String? {
        "register failed"
    }
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
