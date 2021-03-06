//
//  Tempo.Collection.Builder.swift
//  Rhythm
//
//  Created by James Bean on 7/12/17.
//
//

import Collections
import ArithmeticTools

extension Tempo.Interpolation.Collection {

    public final class Builder: MetricalDurationSpanningContainerBuilder {

        public typealias Product = Tempo.Interpolation.Collection

        public var intermediate: SortedDictionary<Fraction,Tempo.Interpolation.Fragment>
        public var offset: Fraction

        private var last: (Fraction, Tempo, Bool)?

        public init() {
            self.intermediate = [:]
            self.offset = .zero
        }

        @discardableResult public func add(_ interpolation: Tempo.Interpolation.Fragment)
            -> Builder
        {
            self.intermediate.insert(interpolation, key: offset)
            last = (offset, interpolation.base.end, true)
            offset += interpolation.range.length
            return self
        }

        @discardableResult public func add(
            _ tempo: Tempo,
            at offset: Fraction,
            interpolating: Bool = false
        ) -> Builder
        {
            if let (startOffset, startTempo, startInterpolating) = last {
                let interpolation = Tempo.Interpolation(
                    start: startTempo,
                    end: startInterpolating ? tempo : startTempo,
                    length: offset - startOffset,
                    easing: .linear
                )
                add(.init(interpolation))
            }
            last = (offset, tempo, interpolating)
            return self
        }
    }
}
