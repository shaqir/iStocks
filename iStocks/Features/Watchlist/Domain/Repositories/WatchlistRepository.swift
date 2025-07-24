import Combine

// MARK: - Base Protocol
protocol WatchlistRepository {
    func observeStocks() -> AnyPublisher<[Stock], Error>
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error>
    func subscribeToSymbols(_ symbols: [String])
}

// MARK: - Mock Repository
/// Mock repo supports both live + rest behavior
protocol MockWatchlistRepository: StockLiveRepository, RestStockRepository {}

// MARK: - REST Repository
protocol RestStockRepository: StockLiveRepository {
    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], Error>
}

// MARK: - WebSocket Repository
protocol StockLiveRepository: WatchlistRepository {}


///Default Implementations
extension WatchlistRepository {
    
    func observeStocks() -> AnyPublisher<[Stock], Error> {
        Empty().setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        Empty().setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func subscribeToSymbols(_ symbols: [String]) {}
    
    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], any Error> {
        
        Empty().setFailureType(to: Error.self).eraseToAnyPublisher()
        
    }
}
