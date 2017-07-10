//
//  Meter.Collection.swift
//  Rhythm
//
//  Created by James Bean on 7/8/17.
//
//

import Foundation
import ArithmeticTools
import Collections

/// This is a momentary fix for: https://github.com/dn-m/Collections/issues/145
extension SortedDictionary {

    public var count: Int {
        return keys.count
    }
}

extension Meter {

    public struct Collection {

        public final class Builder {

            fileprivate var meters: SortedDictionary<Fraction, Meter.Fragment> = [:]
            private var offset: Fraction = .unit

            public init() { }

            public func addMeter(_ meter: Meter.Fragment) {
                self.meters.insert(meter, key: offset)
                offset += meter.range.length
            }

            public func addMeter(_ meter: Meter) {
                let fragment = Fragment(meter)
                addMeter(fragment)
            }

            public func addMeters(_ meters: [Meter.Fragment]) {
                meters.forEach(addMeter)
            }

            public func build() -> Collection {
                return Collection(meters: meters)
            }
        }

        public static let empty = Collection(meters: [:])

        public var beatContexts: [BeatContext] {
            var result: [BeatContext] = []
            for (offset, fragment) in meters {
                let offset = offset.numerator /> offset.denominator
                let meterContext = Meter.Context(meter: fragment.meter, at: offset)

                // FIXME: Use Collection-based Range type
                // FIXME: In Swift 3.1 version, `Rational` is `Strideable`.
                // FIXME: Use CountableClosedRange
                // FIXME: Use `reduce` over countable closed range of `Fraction`.
                var beat = fragment.range.lowerBound
                while beat < fragment.range.upperBound {
                    let beatContext = BeatContext(
                        meterContext: meterContext,
                        offset: beat.numerator /> beat.denominator
                    )
                    result.append(beatContext)
                    beat += Fraction(1, beat.denominator)
                }
            }

            return result
        }

        /// - TODO: Change to `duration`.
        public var duration: MetricalDuration {

            guard !isEmpty else {
                return .unit
            }

            /// FIXME: Make `SortedDictionary` RandomAccessCollection
            let (offset, fragment) = meters[meters.count - 1]
            let totalDuration = offset + fragment.range.length
            return totalDuration.numerator /> totalDuration.denominator
        }

        public let meters: SortedDictionary<Fraction, Meter.Fragment>

        public init(meters: SortedDictionary<Fraction, Meter.Fragment>) {
            self.meters = meters
        }

        public init(_ meters: [Meter.Fragment]) {
            let builder = Builder()
            builder.addMeters(meters)
            self = builder.build()
        }

        public init(_ meters: [Meter]) {
            let builder = Builder()
            builder.addMeters(meters.map { Meter.Fragment($0) })
            self = builder.build()
        }

        public subscript (range: Range<Fraction>) -> Collection {

            guard
                let startIndex = indexOfMeter(containing: range.lowerBound, allowingEnd: false)
            else {
                return .empty
            }

            let endIndex = indexOfMeter(containing: range.upperBound, allowingEnd: true) ?? count - 1

            let start = meterFragment(from: range.lowerBound, at: startIndex)

            /// Single measure
            guard endIndex > startIndex else {
                let (meterOffset, fragment) = meters[startIndex]
                let newFragment = Meter.Fragment(
                    fragment.meter,
                    from: range.lowerBound - meterOffset,
                    to: range.upperBound - meterOffset
                )
                return Collection([newFragment])
            }

            let builder = Builder()

            let end = meterFragment(to: range.upperBound, at: endIndex)

            /// Two consecutive measures
            guard endIndex > startIndex + 1 else {
                builder.addMeters([start,end])
                return builder.build()
            }

            /// Three or more measures
            let innards = meters(in: startIndex + 1 ... endIndex - 1)
            builder.addMeters(start + innards + end)
            return builder.build()
        }

        public subscript (offset: Fraction) -> (Fraction, Meter.Fragment)? {
            guard let index = indexOfMeter(containing: offset) else { return nil }
            return meters[index]
        }

        private func meterFragment(from offset: Fraction, at index: Int) -> Meter.Fragment {
            let (meterOffset, fragment) = meters[index]
            return Meter.Fragment(fragment.meter, from: offset - meterOffset)
        }

        private func meterFragment(to offset: Fraction, at index: Int) -> Meter.Fragment {
            let (meterOffset, fragment) = meters[index]
            return Meter.Fragment(fragment.meter, to: offset - meterOffset)
        }

        private func meters(in range: CountableClosedRange<Int>) -> [Meter.Fragment] {
            return range.map { index in meters[index].1 }
        }

        // Use binary search because we have a sorted collection
        // FIXME: Must refactor
        public func indexOfMeter(containing offset: Fraction, allowingEnd: Bool = false) -> Int? {

            var start = 0
            var end = meters.count

            while start < end {

                let middle = start + (end - start) / 2
                let (meterOffset, meter) = meters[middle]

                /// implict that it doesnt allow start
                if allowingEnd {

                    if offset > meterOffset && offset <= meterOffset + meter.length {
                        return middle
                    }

                    if offset > meterOffset + meter.length {
                        start = middle + 1
                    } else {
                        end = middle
                    }

                } else {

                    if offset >= meterOffset && offset < meterOffset + meter.length {
                        return middle
                    }

                    if offset >= meterOffset + meter.length {
                        start = middle + 1
                    } else {
                        end = middle
                    }
                }
            }
            
            return nil
        }
    }
}

extension Meter.Collection: AnyCollectionWrapping {

    public var collection: AnyCollection<(Fraction,Meter.Fragment)> {
        return AnyCollection(meters)
    }
}

// This is already in newer versions of dn-m/ArithemticTools over all Rational types
extension Fraction: SignedNumber {

    // MARK: - Signed Number
    /// Negate `Rational` type arithmetically.
    public static prefix func - (rational: Fraction) -> Fraction {
        return -rational
    }
}

extension Range where Bound: SignedNumber {

    public var length: Bound {
        return upperBound - lowerBound
    }
}

//// FIXME: Move to dn-m/ArithmeticTools, make generic
//public func - (lhs: ClosedRange<Fraction>, rhs: Fraction) -> ClosedRange<Fraction> {
//    return lhs.lowerBound - rhs ... lhs.upperBound - rhs
//}
//
//public func + (lhs: ClosedRange<Fraction>, rhs: Fraction) -> ClosedRange<Fraction> {
//    return lhs.lowerBound + rhs ... lhs.upperBound + rhs
//}