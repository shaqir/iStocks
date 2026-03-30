import Combine

// MARK: - Base Protocol

/// Common contract for all data source implementations.
/// Mock, REST, WebSocket, and GraphQL repositories all conform to this.  lets four completely different data sources — be swapped at runtime without a single change to the ViewModel or use cases.
 
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
