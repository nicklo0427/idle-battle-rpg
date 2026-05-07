// Image+WebP.swift
// iOS 14+ 原生支援 WebP，透過 ImageIO 從 bundle 讀取
// 用法：Image(webp: "region_wildland")

import SwiftUI

extension Image {
    /// 從 main bundle 載入 .webp 圖片。
    /// 找不到時 fallback 為空白透明圖，不 crash。
    init(webp name: String) {
        if let url  = Bundle.main.url(forResource: name, withExtension: "webp"),
           let data = try? Data(contentsOf: url),
           let ui   = UIImage(data: data) {
            self.init(uiImage: ui)
        } else {
            self.init(uiImage: UIImage())
        }
    }
}
