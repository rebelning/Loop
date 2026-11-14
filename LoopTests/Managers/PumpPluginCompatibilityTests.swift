import Foundation
import XCTest
import LoopKitUI

@MainActor
final class PumpPluginCompatibilityTests: XCTestCase {
    func testApexPluginLoadsAndProvidesPumpManager() throws {
        try verifyPlugin(named: "ApexKitBLEPlugin", identifier: "Apex")
    }

    func testEmbectaPluginLoadsAndProvidesPumpManager() throws {
        try verifyPlugin(named: "EmbectaKitBLEPlugin", identifier: "Embecta")
    }

    private func verifyPlugin(named name: String, identifier: String) throws {
        let frameworks = try XCTUnwrap(Bundle.main.privateFrameworksURL)
        let bundle = try XCTUnwrap(Bundle(url: frameworks.appendingPathComponent(name + ".framework")))
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "com.loopkit.Loop.PumpManagerIdentifier") as? String, identifier)
        try bundle.loadAndReturnError()
        let principalClass = try XCTUnwrap(bundle.principalClass as? NSObject.Type)
        let plugin = try XCTUnwrap(principalClass.init() as? PumpManagerUIPlugin)
        let managerType = try XCTUnwrap(plugin.pumpManagerType)
        XCTAssertEqual(managerType.pluginIdentifier, identifier)
    }
}
