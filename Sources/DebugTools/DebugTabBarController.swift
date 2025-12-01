import UIKit
import Pulse
import PulseUI
import SwiftUI

class DebugTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        let pulseVC = UIHostingController(rootView: NavigationView {
            ConsoleView()
        })
        pulseVC.tabBarItem = UITabBarItem(title: "Pulse", image: UIImage(systemName: "network"), tag: 0)
        
        let sandboxVC = SandboxViewController()
        sandboxVC.tabBarItem = UITabBarItem(title: "Sandbox", image: UIImage(systemName: "folder"), tag: 1)
        
        // let pulseNav = UINavigationController(rootViewController: pulseVC)
        let sandboxNav = UINavigationController(rootViewController: sandboxVC)
        
        // pulseNav.navigationBar.prefersLargeTitles = true
        sandboxNav.navigationBar.prefersLargeTitles = true
        
        viewControllers = [pulseVC, sandboxNav]
        
        
        sandboxVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeDebugTools))
        
    }
    
    
    
    @objc private func closeDebugTools() {
        dismiss(animated: true)
    }
}
