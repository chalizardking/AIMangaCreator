import Foundation

enum AppError: LocalizedError {
    case invalidInput(String)
    case apiError(APIErrorCode, String)
    case fileNotFound(String)
    case fileWriteFailed(String)
    case imageProcessingFailed(String)
    case networkError(URLError)
    case unsupportedFileFormat(String)
    case insufficientDiskSpace
    case unauthorized(String)
    case rateLimited(retryAfter: TimeInterval)
    case notImplemented(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let msg):
            return "Invalid Input: \(msg)"
        case .apiError(let code, let msg):
            return "API Error (\(code.rawValue)): \(msg)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileWriteFailed(let msg):
            return "Could not save file: \(msg)"
        case .imageProcessingFailed(let msg):
            return "Image processing failed: \(msg)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unsupportedFileFormat(let format):
            return "Unsupported format: \(format)"
        case .insufficientDiskSpace:
            return "Not enough disk space to save project"
        case .unauthorized(let msg):
            return "Unauthorized: \(msg)"
        case .rateLimited(let retryAfter):
            return "Rate limited. Retry in \(Int(retryAfter)) seconds."
        case .notImplemented(let feature):
            return "Feature not yet implemented: \(feature)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Check your input and try again."
        case .apiError:
            return "Check your API keys and network connection."
        case .fileNotFound:
            return "The file may have been moved or deleted."
        case .insufficientDiskSpace:
            return "Free up disk space and try again."
        case .rateLimited(let retryAfter):
            return "Wait \(Int(retryAfter)) seconds before retrying."
        case .notImplemented:
            return "This feature will be available in a future update."
        default:
            return "Please try again or contact support."
        }
    }
}

enum APIErrorCode: String {
    case invalidRequest = "invalid_request_error"
    case authentication = "authentication_error"
    case rateLimit = "rate_limit_error"
    case server = "server_error"
    case unknown = "unknown_error"
}
