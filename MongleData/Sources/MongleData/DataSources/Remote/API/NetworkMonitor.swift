import Network
import Foundation

/// 실시간 네트워크 연결 상태를 감지하는 싱글톤.
/// APIClient가 오프라인 요청을 즉시 차단하는 데 사용.
public final class NetworkMonitor: @unchecked Sendable {

    public static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.mongle.NetworkMonitor", qos: .utility)

    // Thread-safe access via NSLock
    private let lock = NSLock()
    private var _isConnected: Bool = true

    public var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isConnected
    }

    public enum ConnectionType: String, Sendable {
        case wifi, cellular, ethernet, unknown
    }

    private var _connectionType: ConnectionType = .unknown
    public var connectionType: ConnectionType {
        lock.lock()
        defer { lock.unlock() }
        return _connectionType
    }

    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.lock.lock()
            self._isConnected = path.status == .satisfied
            self._connectionType = Self.type(for: path)
            self.lock.unlock()
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private static func type(for path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }
}
