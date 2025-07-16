import Combine

//Abstracts stock-fetching logic
protocol WatchlistRepository {
    func observeTop5Stocks() -> AnyPublisher<[Stock], Error>
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error>

    // Generic fallback used by mock mode
    func observeStocks() -> AnyPublisher<[Stock], Error>
}

//Default: return empty publisher for non-mock (REST) mode
//Override it in future when you implement Price Update for REST mode too
extension WatchlistRepository {
    func observeStocks() -> AnyPublisher<[Stock], Error> {
        return Empty(completeImmediately: true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
