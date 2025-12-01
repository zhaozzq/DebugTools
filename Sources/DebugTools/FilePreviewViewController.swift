import UIKit
import QuickLook
import WebKit

class FilePreviewViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate, WKNavigationDelegate {
    private let filePath: String
    private let textView = UITextView()
    private let previewController = QLPreviewController()
    private let webView = WKWebView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // 文件类型枚举，使文件类型处理更加结构化
    private enum FileType {
        case quickLookSupported // PDF、图片、视频等
        case json
        case html
        case xml
        case text
        case binary
        
        init(filePath: String) {
            let fileExtension = (filePath as NSString).pathExtension.lowercased()
            
            // 检查 QuickLook 支持的类型
            let quickLookSupportedTypes = [
                // 图片
                "jpg", "jpeg", "png", "gif", "tiff", "tif", "bmp", "heic", "heif",
                // PDF
                "pdf",
                // 视频
                "mp4", "mov", "avi", "mkv", "wmv", "flv", "m4v", "3gp", "webm"
            ]
            
            if quickLookSupportedTypes.contains(fileExtension) {
                self = .quickLookSupported
            } else if fileExtension == "json" {
                self = .json
            } else if ["html", "htm"].contains(fileExtension) {
                self = .html
            } else if ["xml", "plist"].contains(fileExtension) {
                self = .xml
            } else {
                // 默认分类，后续会根据文件内容进一步判断
                self = .text
            }
        }
    }
    
    private var fileType: FileType {
        return FileType(filePath: filePath)
    }
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActivityIndicator()
        
        // 显示加载指示器
        showLoading()
        
        // 根据文件类型选择合适的预览方式
        DispatchQueue.global(qos: .userInitiated).async {
            // 在后台线程判断文件类型并准备数据
            let fileType = self.fileType
            
            DispatchQueue.main.async {
                self.hideLoading()
                
                switch fileType {
                case .quickLookSupported:
                    self.setupAndShowQuickLook()
                case .html:
                    self.setupAndShowWebView()
                case .json, .xml, .text, .binary:
                    self.loadFileContent()
                }
            }
        }
    }
    
    private func setupUI() {
        title = (filePath as NSString).lastPathComponent
        view.backgroundColor = .systemBackground
        
        // 初始设置 textView 作为备用视图
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .systemBackground
        textView.isHidden = true
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 添加共享按钮
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(shareFile)
            ),
            // 添加文件信息按钮
            UIBarButtonItem(
                image: UIImage(systemName: "info.circle"),
                style: .plain,
                target: self,
                action: #selector(showFileInfo)
            )
            
        ]
        
    }
    
    private func loadFileContent() {
        showLoading()
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileManager = FileManager.default
                let attributes = try fileManager.attributesOfItem(atPath: self.filePath)
                let fileSize = attributes[.size] as? Int64 ?? 0
                let creationDate = attributes[.creationDate] as? Date ?? Date()
                let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                
                var resultText = ""
                
                // 添加文件信息头部
                resultText += "File: \((self.filePath as NSString).lastPathComponent)\n"
                resultText += "Size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))\n"
                resultText += "Created: \(self.formatDate(creationDate))\n"
                resultText += "Modified: \(self.formatDate(modificationDate))\n\n"
                
                if fileSize > 1024 * 1024 { // 1MB limit
                    resultText += "File too large to preview"
                } else if let content = try? String(contentsOfFile: self.filePath, encoding: .utf8) {
                    // 根据文件类型进行格式化
                    switch self.fileType {
                    case .json:
                        resultText += self.formatJSON(content)
                    case .xml:
                        resultText += self.formatXML(content)
                    case .text, .html, .quickLookSupported, .binary:
                        resultText += content
                    }
                } else if let data = try? Data(contentsOf: URL(fileURLWithPath: self.filePath)) {
                    resultText += "Binary file\n\nHex dump:\n\(data.prefix(1024).hexString)"
                } else {
                    resultText += "Unable to read file content"
                }
                
                DispatchQueue.main.async {
                    self.hideLoading()
                    self.textView.isHidden = false
                    self.textView.text = resultText
                    // 滚动到顶部
                    self.textView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
                }
            } catch {
                DispatchQueue.main.async {
                    self.hideLoading()
                    self.textView.isHidden = false
                    self.textView.text = "Error reading file: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - WebView 相关方法
    private func setupAndShowWebView() {
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 添加刷新按钮
        navigationItem.rightBarButtonItems?.append(UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(reloadWebView)
        ))
        
        loadHTMLFile()
    }
    
    private func loadHTMLFile() {
        showLoading()
        let url = URL(fileURLWithPath: filePath)
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    
    // MARK: - WKNavigationDelegate
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoading()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideLoading()
        // 加载失败，切换回文本视图
        webView.removeFromSuperview()
        textView.isHidden = false
        
        if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
            textView.text = "Failed to load HTML with WebKit. Showing raw content instead.\n\nError: \(error.localizedDescription)\n\n\(content)"
        } else {
            textView.text = "Failed to load HTML: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 辅助方法
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func showLoading() {
        activityIndicator.startAnimating()
    }
    
    private func hideLoading() {
        activityIndicator.stopAnimating()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - 操作方法
    @objc private func reloadWebView() {
        webView.reload()
        showLoading()
    }
    
    @objc private func showFileInfo() {
        do {
            let fileManager = FileManager.default
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            
            var infoText = "File Information:\n\n"
            infoText += "Name: \((filePath as NSString).lastPathComponent)\n"
            infoText += "Path: \(filePath)\n"
            
            if let size = attributes[.size] as? Int64 {
                infoText += "Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))\n"
            }
            
            if let creationDate = attributes[.creationDate] as? Date {
                infoText += "Created: \(formatDate(creationDate))\n"
            }
            
            if let modificationDate = attributes[.modificationDate] as? Date {
                infoText += "Modified: \(formatDate(modificationDate))\n"
            }
            
            if let type = attributes[.type] as? FileAttributeType {
                infoText += "Type: \(type.rawValue)\n"
            }
            
            let alert = UIAlertController(title: "File Info", message: infoText, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } catch {
            let alert = UIAlertController(title: "Error", message: "Unable to retrieve file info: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    // MARK: - 文件格式化方法
    private func formatJSON(_ jsonString: String) -> String {
        // 尝试解析和格式化 JSON
        if let data = jsonString.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        return jsonString // 如果格式化失败，返回原始字符串
    }
    
    private func formatXML(_ xmlString: String) -> String {
        // 简单的 XML 格式化逻辑
        let trimmedString = xmlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 基本的缩进处理
        var result = ""
        var indentLevel = 0
        var inTag = false
        var inClosingTag = false
        var lastChar: Character?
        
        for char in trimmedString {
            if char == "<" {
                inTag = true
                if lastChar != "\n" && !result.isEmpty {
                    result += "\n"
                    result += String(repeating: "    ", count: indentLevel)
                }
            } else if char == "/" && lastChar == "<" {
                inClosingTag = true
            } else if char == ">" {
                inTag = false
                if inClosingTag {
                    indentLevel = max(0, indentLevel - 1)
                    inClosingTag = false
                } else if !trimmedString.contains("</") {
                    // 自闭合标签不增加缩进
                } else {
                    // 检查是否是闭合标签
                    let previousChars = String(result.suffix(10))
                    if !previousChars.contains("/") {
                        indentLevel += 1
                    }
                }
            }
            
            result.append(char)
            lastChar = char
        }
        
        return result
    }
    
    @objc private func shareFile() {
        let url = URL(fileURLWithPath: filePath)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
    
    // MARK: - QuickLook 相关方法
    private func setupQuickLook() {
        previewController.dataSource = self
        previewController.delegate = self
        previewController.currentPreviewItemIndex = 0
        
        // 将 QuickLook 控制器添加为子视图控制器
        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            previewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        previewController.didMove(toParent: self)
    }
    
    // MARK: - QuickLook 相关方法
    private func setupAndShowQuickLook() {
        previewController.dataSource = self
        previewController.delegate = self
        previewController.currentPreviewItemIndex = 0
        
        // 将 QuickLook 控制器添加为子视图控制器
        addChild(previewController)
        view.addSubview(previewController.view)
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            previewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        previewController.didMove(toParent: self)
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return URL(fileURLWithPath: filePath) as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // 可以在这里添加一些清理逻辑
    }
    
    // MARK: - 视图生命周期
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 清理 webView 的加载任务
        webView.stopLoading()
    }
}

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
