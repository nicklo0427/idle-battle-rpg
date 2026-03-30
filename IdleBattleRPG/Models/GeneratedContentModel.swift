import Foundation
import SwiftData

@Model
final class GeneratedContentModel {
    @Attribute(.unique) var cacheKey: String
    var content: String
    var generatedAt: Date
    var contentType: String

    init(cacheKey: String, content: String, contentType: String) {
        self.cacheKey = cacheKey
        self.content = content
        self.generatedAt = .now
        self.contentType = contentType
    }
}
