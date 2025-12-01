import OSLog
import Logging

public struct OSLogHandler: LogHandler {
    
    private let logger: os.Logger
    
    public var label: String
    public var logLevel: Logging.Logger.Level = .trace
    public var metadata = Logging.Logger.Metadata()
    public var metadataProvider: Logging.Logger.MetadataProvider?
    
    public init(label: String) {
        self.label = label
        self.logger = os.Logger(subsystem: label, category: "OSLogHandler")
    }
    
    public init(label: String, logger: os.Logger) {
        self.label = label
        self.logger = logger
    }
    
    public func log(
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata: Logging.Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        switch level {
        case .trace:
            logger.trace("\(message, privacy: .public)")
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .notice:
            logger.notice("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .critical:
            logger.critical("\(message, privacy: .public)")
        }
    }
    
    public subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
    
    /// Merges metadata from a log entry metadata with the metadata set on this logger and any metadata
    /// returned from the metadata provider, if present.
    ///
    /// When multiple sources of metadata return values for the same key, the more specific value will win,
    /// i.e. the priority from least to most specific is: the metadata provider, the handler's metadata, then
    /// finally the log entry's metadata.
    ///
    private func mergedMetadata(with metadata: Logging.Logger.Metadata?) -> Logging.Logger.Metadata {
        return (metadata ?? [:])
            .merging(self.metadata, uniquingKeysWith: { (current, _) in current })
            .merging(self.metadataProvider?.get() ?? [:], uniquingKeysWith: { (current, _) in current })
    }
    
}
