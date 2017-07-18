//
//  SpanningFragment.swift
//  Rhythm
//
//  Created by James Bean on 7/18/17.
//
//

import ArithmeticTools

/// Interface extending `Spanning` types, which also carry with them a range of operation.
// FIXME: Use constrained associated types (Metric == Fragment.Metric)
public protocol SpanningFragment: Spanning, Fragmentable {

    // MARK: - Instance Properties

    /// The range of operation.
    var range: Range<Metric> { get }
}

extension SpanningFragment {

    /// The length of `SpanningFragment`.
    public var length: Metric {
        return range.length
    }
}

extension SpanningFragment where Fragment == Self {

    /// - Returns: A fragment of self from lower bound to the given `offset`.
    public func to(_ offset: Metric) -> Self {
        assert(offset <= self.range.upperBound)
        let range = self.range.lowerBound ..< offset
        return self[range]
    }

    /// - Returns: A fragment of self from the given `offset` to upper bound.
    public func from(_ offset: Metric) -> Self {
        assert(offset >= self.range.lowerBound)
        let range = offset ..< self.range.upperBound
        return self[range]
    }
}
