//
//  DebugWindow.swift
//  DebugTools
//
//  Created by zhaozq on 2025/11/25.
//

import UIKit

protocol DebugWindowDelegate: AnyObject {
    func isPointEvent(point: CGPoint) -> Bool
}

class DebugWindow: UIWindow {
    
    weak var delegate: DebugWindowDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.windowLevel = UIWindow.Level.alert + 1
    }
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self.backgroundColor = .clear
        self.windowLevel = UIWindow.Level.alert + 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.delegate?.isPointEvent(point: point) ?? false
    }
}

//extension WindowHelper: WindowDelegate {
//    func isPointEvent(point: CGPoint) -> Bool {
//        return self.vc.shouldReceive(point: point)
//    }
//}
