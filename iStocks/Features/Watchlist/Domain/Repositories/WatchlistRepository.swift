import Combine

//Abstracts stock-fetching logic
protocol WatchlistRepository {
    func observeTop5Stocks() -> AnyPublisher<[Stock], Error>
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error>

    // Generic fallback used by mock mode
    func observeStocks() -> AnyPublisher<[Stock], Error>
}
