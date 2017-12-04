import Hashing
import WeakSet

public class YDDFactory<Key> where Key: Comparable & Hashable {

    public init() {
        self.zero = YDD(factory: self, count: 0)
        self.uniquenessTable.insert(self.zero)
        self.one  = YDD(factory: self, count: 1)
        self.uniquenessTable.insert(self.one)
    }

    public func make<S>(_ sequence: S) -> YDD<Key> where S: Sequence, S.Element == Key {
        let set = Set(sequence)
        guard !set.isEmpty else {
            return self.one
        }

        var result = self.one!
        for element in sequence.sorted().reversed() {
            result = self.makeNode(key: element, take: result, skip: self.zero)
        }
        return result
    }

    public func make<S>(_ sequences: S) -> YDD<Key>
        where S: Sequence, S.Element: Sequence, S.Element.Element == Key
    {
        return sequences.reduce(self.zero) { family, newMember in
            family.union(self.make(newMember))
        }
    }

    public func make<S>(_ sequences: S...) -> YDD<Key> where S: Sequence, S.Element == Key {
        return self.make(sequences)
    }

    public func makeNode(key: Key, take: YDD<Key>, skip: YDD<Key>) -> YDD<Key> {
        guard take !== self.zero else {
            return skip
        }

        assert(take.isTerminal || key < take.key, "invalid YDD ordering")
        assert(skip.isTerminal || key < skip.key, "invalid YDD ordering")

        let (_, result) = self.uniquenessTable.insert(
            YDD(key: key, take: take, skip: skip, factory: self),
            withCustomEquality: YDD<Key>.areEqual)
        return result
    }

    public private(set) var zero: YDD<Key>! = nil
    public private(set) var one : YDD<Key>! = nil

    var unionCache              : [CacheKey<Key>: YDD<Key>] = [:]
    var intersectionCache       : [CacheKey<Key>: YDD<Key>] = [:]
    var symmetricDifferenceCache: [CacheKey<Key>: YDD<Key>] = [:]
    var subtractionCache        : [CacheKey<Key>: YDD<Key>] = [:]
    private var uniquenessTable : WeakSet<YDD<Key>> = []

}

// MARK: Caching

struct CacheKey<Key>: Hashable where Key: Comparable & Hashable {

    let operands: [YDD<Key>]

    var hashValue: Int {
        return hash(operands.map({ $0.hashValue }))
    }

    static func ==(lhs: CacheKey, rhs: CacheKey) -> Bool {
        return lhs.operands == rhs.operands
    }

}