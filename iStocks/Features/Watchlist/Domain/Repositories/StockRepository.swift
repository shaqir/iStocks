import Combine

//Abstracts stock-fetching logic
protocol StockRepository {
    func observeTop5Stocks() -> AnyPublisher<[Stock], Error>
    func observeTop50Stocks() -> AnyPublisher<[Stock], Never>

    // Generic fallback used by mock mode
    func observeStocks() -> AnyPublisher<[Stock], Error>
}
