// DeterministicRNG.swift
// 確定性種子 RNG（LCG 演算法）
//
// 設計原則：
//   - 同一筆任務在相同 seed 下，結果序列永遠相同（可重現 / 可驗證）
//   - 無全域隨機狀態，完全不依賴 Int.random(in:) 或 Double.random(in:)
//   - 純 value type（struct），不含副作用，可單元測試
//
// Seed 派生（規格定義）：
//   seed = startedAt.bitPattern XOR UInt64(bitPattern: taskId.hashValue)
//
// LCG 參數（Knuth）：
//   state = state × 6364136223846793005 + 1442695040888963407

import Foundation

struct DeterministicRNG {

    private var state: UInt64

    // MARK: - 初始化

    /// 直接以 seed 建立 RNG（測試 / 特殊用途）
    init(seed: UInt64) {
        // seed=0 會讓 LCG 陷入全零序列，改用固定非零值
        state = seed == 0 ? 6364136223846793005 : seed
    }

    /// 從 TaskModel 派生 seed（正式使用入口）
    /// seed = startedAt 的 IEEE 754 bit pattern XOR taskId.hashValue 的 bit pattern
    init(task: TaskModel) {
        let t = task.startedAt.timeIntervalSinceReferenceDate.bitPattern
        let h = UInt64(bitPattern: Int64(truncatingIfNeeded: task.id.hashValue))
        self.init(seed: t ^ h)
    }

    // MARK: - 生成方法

    /// 推進 LCG 狀態，回傳下一個 UInt64
    mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    /// 均勻分佈 Double，範圍 [0.0, 1.0)
    /// 取高 53 bit 對應 Double 有效精度
    mutating func nextDouble() -> Double {
        Double(nextUInt64() >> 11) / Double(1 << 53)
    }

    /// 在 ClosedRange<Int> 內均勻取整數（包含上下界）
    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        guard span > 0 else { return range.lowerBound }
        return range.lowerBound + Int(nextUInt64() % span)
    }
}
