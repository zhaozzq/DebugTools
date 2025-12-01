import Logging

public struct MultiLogHandler {
    
    public var label: String
    public var logLevel = Logging.Logger.Level.info
    public var metadata = Logging.Logger.Metadata()
    public var metadataProvider: Logging.Logger.MetadataProvider?
    
    private var handlers: [any LogHandler]
    
    
    public init(label: String, handlers: [any LogHandler]) {
        self.init(label: label, handlers: handlers, metadataProvider: nil)
    }
    
    public init(label: String, handlers: [any LogHandler], metadataProvider: Logging.Logger.MetadataProvider?) {
        self.label = label;
        self.handlers = handlers
        self.metadataProvider = metadataProvider
    }
}

extension MultiLogHandler: LogHandler {
    public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get {
            metadata[key]
        } set(newValue) {
            metadata[key] = newValue
        }
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
        handlers.forEach { handler in
            handler.log(
                level: level,
                message: message,
                metadata: mergedMetadata(with: metadata),
                source: source,
                file: file,
                function: function,
                line: line
            )
        }
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
