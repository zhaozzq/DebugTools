import UIKit
import Pulse
import PulseUI
import PulseProxy

public class DebugTools {
    public static let shared = DebugTools()
    
    private var debugWindow: DebugWindow?
    private var isShowing = false
    var displayedMain = false
    
    private init() {}
    
    public func setup() {
#if DEBUG
        setupShakeGesture()
        NetworkLogger.enableProxy()
        show()
#endif
        if #available(iOS 13.0, *) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: { [weak self] in
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        self?.debugWindow?.windowScene = windowScene
                    }
                }
            })
        }
        
    }
    
    public func show() {
        guard !isShowing else { return }
        isShowing = true
        
        let debug = DebugViewController()
        
        // 获取当前的 windowScene
        var windowScene: UIWindowScene?
        if #available(iOS 13.0, *) {
            windowScene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
        }
        
        if #available(iOS 13.0, *), let scene = windowScene {
            debugWindow = DebugWindow(windowScene: scene)
        } else {
            debugWindow = DebugWindow(frame: UIScreen.main.bounds)
        }
        debugWindow?.rootViewController = debug
        debugWindow?.delegate = debug
        debugWindow?.makeKeyAndVisible()
    }
    
    public func hide() {
        debugWindow?.isHidden = true
        debugWindow = nil
        isShowing = false
    }
    
    private func setupShakeGesture() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceShaken),
            name: UIDevice.deviceDidShakeNotification,
            object: nil
        )
    }
    
    @objc private func deviceShaken() {
        if isShowing {
            hide()
        } else {
            show()
        }
    }
    
    func showMainDebugView() {
        self.displayedMain = true
        
        let main = DebugTabBarController()
        main.modalPresentationStyle = .fullScreen
        debugWindow?.rootViewController?.present(main, animated: true, completion: nil)
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
