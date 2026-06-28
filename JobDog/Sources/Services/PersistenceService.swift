import Foundation

// MARK: - 持久化服务

/// JSON 原子写入：tmp → replaceItem → backup
class PersistenceService {
    private let fileManager = FileManager.default
    private let saveURL: URL
    private let backupURL: URL

    init() {
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        saveURL = docsDir.appendingPathComponent(AppConfig.saveFileName)
        backupURL = docsDir.appendingPathComponent(AppConfig.backupFileName)
    }

    /// 保存存档（原子写入）
    func save(_ data: SaveData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)

        // 1. 写入临时文件
        let tmpURL = saveURL.deletingLastPathComponent()
            .appendingPathComponent("save.json.tmp")
        try jsonData.write(to: tmpURL, options: .atomic)

        // 2. 备份旧文件
        if fileManager.fileExists(atPath: saveURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.moveItem(at: saveURL, to: backupURL)
        }

        // 3. 原子替换
        try fileManager.replaceItem(at: saveURL, withItemAt: tmpURL)
    }

    /// 加载存档（优先主文件，失败尝试备份）
    func load() -> SaveData? {
        if let data = tryLoad(from: saveURL) {
            return data
        }
        // 尝试备份
        if let data = tryLoad(from: backupURL) {
            return data
        }
        return nil
    }

    /// 删除存档（用于重置）
    func deleteSave() {
        try? fileManager.removeItem(at: saveURL)
        try? fileManager.removeItem(at: backupURL)
    }

    // MARK: - Private

    private func tryLoad(from url: URL) -> SaveData? {
        guard let jsonData = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SaveData.self, from: jsonData)
    }
}
