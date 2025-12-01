//
//  ViewController.swift
//  DebugTools-Example
//
//  Created by zhaozq on 2025/11/25.
//

import UIKit
import DebugTools
import OSLog
import Logging
import Pulse
import PulseLogHandler

/// 根配置数据模型，用于展示调试工具的配置项
public struct ConfigItem {
    public let title: String
    public let subtitle: String?
    public let action: () -> Void
    
    public init(title: String, subtitle: String, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.subtitle = nil
    }
}

/// 根配置数据展示控制器，用于展示调试工具的配置项列表
class ViewController: UIViewController {
    
    private let tableView = UITableView()
    private var configItems: [ConfigItem] = []
    private let oslogger = os.Logger(subsystem: "com.zhao.oslog", category: "Logging")
    private let logStore: LoggerStore = .shared
    
    private let logger = Logging.Logger(label: "com.zhao.swift-log")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DebugTools.shared.setup()
        setupUI()
        loadConfigItems()
    }
    
    private func setupUI() {
        title = "Demo"
        view.backgroundColor = .systemBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ConfigCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadConfigItems() {
        // 示例配置项，实际使用时可以从外部传入或动态生成
        configItems = [
            ConfigItem(title: "print", subtitle: "", action: {
                print("print action triggered")
            }),
            ConfigItem(title: "OSLog") { [weak self] in
                self?.oslogger.info("OSLog action triggered")
            },
            
            ConfigItem(title: "Pulse") { [weak self] in
                self?.logStore.storeMessage(label: "Pulse", level: .info, message: "Pulse log action triggered")
            },
            
            ConfigItem(title: "swift-log") { [weak self] in
//                let log = Logging.Logger(label: "com.zhao.swift-log")
//                log.info("swift-log action triggered")
                self?.logger.info("swift-log action triggered")
            },
            
            ConfigItem(title: "swift-log error") { [weak self] in
                self?.logger.error("swift-log action triggered")
            },
        ]
        
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return configItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigCell", for: indexPath)
        let configItem = configItems[indexPath.row]
        
        cell.textLabel?.text = configItem.title
        cell.detailTextLabel?.text = configItem.subtitle
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let configItem = configItems[indexPath.row]
        configItem.action()
    }
}
