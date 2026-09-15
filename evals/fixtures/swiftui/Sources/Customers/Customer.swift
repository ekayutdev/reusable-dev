public struct Customer: Sendable {
    public let id: String
    public let name: String
    public let balanceCents: Int

    public init(id: String, name: String, balanceCents: Int) {
        self.id = id
        self.name = name
        self.balanceCents = balanceCents
    }
}
