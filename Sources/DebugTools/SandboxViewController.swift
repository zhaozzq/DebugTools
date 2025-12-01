import UIKit

class SandboxViewController: UIViewController {
    private let tableView = UITableView()
    private var currentPath: String
    private var items: [FileItem] = []
    
    init(path: String = NSHomeDirectory()) {
        self.currentPath = path
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadItems()
    }
    
    private func setupUI() {
        // 根据当前路径设置标题：根目录显示"Sandbox"，其他显示文件夹名称
        if currentPath == NSHomeDirectory() {
            title = "Sandbox"
        } else {
            // 提取文件夹名称作为标题
            title = (currentPath as NSString).lastPathComponent
        }
        view.backgroundColor = .systemBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadItems() {
        items.removeAll()
        
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: currentPath)
            
            for item in contents.sorted() {
                let fullPath = (currentPath as NSString).appendingPathComponent(item)
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                    let fileItem = FileItem(
                        name: item,
                        path: fullPath,
                        isDirectory: isDirectory.boolValue
                    )
                    items.append(fileItem)
                }
            }
        } catch {
            print("Error loading directory: \(error)")
        }
        
        tableView.reloadData()
    }
}

extension SandboxViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]
        
        cell.textLabel?.text = item.name
        cell.imageView?.image = UIImage(systemName: item.isDirectory ? "folder" : "doc")
        cell.accessoryType = item.isDirectory ? .disclosureIndicator : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = items[indexPath.row]
        
        if item.isDirectory {
            let sandboxVC = SandboxViewController(path: item.path)
            navigationController?.pushViewController(sandboxVC, animated: true)
        } else {
            showFilePreview(for: item)
        }
    }
    
    private func showFilePreview(for item: FileItem) {
        let previewVC = FilePreviewViewController(filePath: item.path)
        navigationController?.pushViewController(previewVC, animated: true)
    }
}

struct FileItem {
    let name: String
    let path: String
    let isDirectory: Bool
}