import Foundation

/// A deterministic pseudo-random number generator based on a 64-bit LCG.
/// Given the same seed, produces identical sequences — making offline
/// calculation reproducible and cheat-resistant.
struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 6364136223846793005 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextFloat() -> Float {
        Float(next() >> 33) / Float(1 << 31)
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        return range.lowerBound + Int(next() % UInt64(span))
    }

    mutating func nextBool(probability: Double) -> Bool {
        nextDouble() < probability
    }
}
