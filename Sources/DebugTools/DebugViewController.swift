//
//  DebugViewController.swift
//  DebugTools
//
//  Created by zhaozq on 2025/11/25.
//

import UIKit

class DebugViewController: UIViewController {
    
    lazy var bubble: UIButton = {
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 35, y: UIScreen.main.bounds.height/2, width: 30, height: 30))
        button.setBackgroundImage(UIImage(systemName: "hammer.circle.fill"), for: .normal)
        button.layer.cornerRadius = 15
        button.backgroundColor = .white.withAlphaComponent(0.8)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        
        button.addTarget(self, action: #selector(DebugViewController.action(_:)), for: .touchUpInside)
        
        // Add pan gesture for dragging
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        button.addGestureRecognizer(pan)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(bubble)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DebugTools.shared.displayedMain = false
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
                self.bubble.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                self.bubble.alpha = 0.9
            }
        }
        
        let translation = gesture.translation(in: view)
        gesture.setTranslation(.zero, in: view)
        
        var center = bubble.center
        center.x += translation.x
        center.y += translation.y
        
        let safeAreaInsets = view.safeAreaInsets
        let halfWidth = bubble.bounds.width / 2
        let halfHeight = bubble.bounds.height / 2
        
        // 拖拽时限制边界
        center.x = max(halfWidth + safeAreaInsets.left, min(center.x, view.bounds.width - halfWidth - safeAreaInsets.right))
        center.y = max(halfHeight + safeAreaInsets.top, min(center.y, view.bounds.height - halfHeight - safeAreaInsets.bottom))
        
        bubble.center = center
        
        if gesture.state == .ended || gesture.state == .cancelled {
            let velocity = gesture.velocity(in: view)
            let location = bubble.center
            
            var finalX: CGFloat
            var finalY = location.y
            
            // 智能吸边：考虑速度方向
            if abs(velocity.x) > 500 {
                finalX = velocity.x > 0 ? view.bounds.width - halfWidth - safeAreaInsets.right : halfWidth + safeAreaInsets.left
            } else {
                finalX = location.x < view.bounds.width / 2 ? halfWidth + safeAreaInsets.left : view.bounds.width - halfWidth - safeAreaInsets.right
            }
            
            let velocityMagnitude = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            let distance = sqrt(pow(finalX - location.x, 2) + pow(finalY - location.y, 2))
            
            // 根据速度和距离计算动画参数
            var duration: TimeInterval = 0.4
            var damping: CGFloat = 0.8
            var initialVelocity: CGFloat = 0
            
            if velocityMagnitude > 800 {
                finalY += velocity.y * 0.15
                finalY = max(halfHeight + safeAreaInsets.top, min(finalY, view.bounds.height - halfHeight - safeAreaInsets.bottom))
                duration = min(0.6, distance / velocityMagnitude * 2)
                damping = 0.65
                initialVelocity = min(velocityMagnitude / 1000, 8)
            }
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: initialVelocity, options: [.allowUserInteraction, .curveEaseOut]) {
                self.bubble.center = CGPoint(x: finalX, y: finalY)
                self.bubble.transform = .identity
                self.bubble.alpha = 1.0
            }
        }
    }
    
    @objc private func action(_ sender: UIButton) {
        DebugTools.shared.showMainDebugView()
    }
    
}

extension DebugViewController: DebugWindowDelegate {
    func isPointEvent(point: CGPoint) -> Bool {
        if DebugTools.shared.displayedMain {
            return true
        }
        return bubble.frame.contains(point)
    }
}


