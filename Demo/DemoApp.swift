import SwiftUI
import HostMemoryResidency
import HostMemoryResidencyUI

/// Which device class this build is actually running on.
///
/// This lives in the **app**, not the library, on purpose. The library takes a
/// `DeviceMemoryTier` as an input because only the host knows what hardware it
/// woke up on — and because a library that reads `ProcessInfo` directly cannot
/// be tested against a device it is not currently running on.
enum DeviceClassifier {

    /// Thresholds are stated as fractions of a gigabyte and compared against
    /// `physicalMemory`, which is a `UInt64`. `Int(clamping:)` is used rather
    /// than `Int(_:)` so a future machine with more RAM than `Int.max` bytes
    /// cannot trap this at launch.
    static func tier(forPhysicalMemory bytes: UInt64) -> DeviceMemoryTier {
        let gigabyte = 1_073_741_824
        let gigabytes = Int(clamping: bytes) / gigabyte
        switch gigabytes {
        case ..<4: return .constrained
        case 4..<8: return .standard
        default: return .generous
        }
    }

    static var current: DeviceMemoryTier {
        tier(forPhysicalMemory: ProcessInfo.processInfo.physicalMemory)
    }
}

/// A compact strip above the library's own screen, showing what this build
/// detected about itself and what budget the library resolves for it.
///
/// This is the app's half of the contract: the app supplies the host class, the
/// library supplies the policy. The same `tier` is handed to `ResidencyDemoView`
/// below, so the screen really is planning against this device.
struct DeviceBanner: View {

    let tier: DeviceMemoryTier
    @State private var footprint: ByteCount = .zero

    private var host: HostClass {
        HostClass(kind: .application, tier: tier)
    }

    private var budget: HostBudget? {
        HostBudgetTable.illustrative.budget(for: host)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Detected: \(host.description)")
                .font(.footnote.weight(.semibold))
            if let budget {
                Text("as an app it would get \(budget.headroom.description) of headroom · using \(footprint.description) right now")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            Text("The device class below is this one. Change the host picker to see what the same core costs elsewhere.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .task {
            footprint = await DefaultFootprintProbe().currentFootprint()
        }
    }
}

@main
struct DemoApp: App {

    /// Classified once at launch and handed to both halves of the screen. The
    /// library never reads `ProcessInfo` itself — device detection is the app's
    /// job, policy is the library's.
    private let tier = DeviceClassifier.current

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                DeviceBanner(tier: tier)
                Divider()
                ResidencyDemoView(hostKind: .widgetExtension, tier: tier)
            }
        }
    }
}
