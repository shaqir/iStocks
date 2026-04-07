//
//  WebSocketStockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-17.
//
// WebSocketStockRepository.swift

import Foundation
import Combine

/// NOTE (Swift 6.2): nonisolated + @unchecked Sendable because this is a Data layer class
/// managing WebSocket I/O. Thread safety is guaranteed by the Combine pipeline running on
/// RunLoop.main and the StockStateActor protecting shared mutable stock state.
nonisolated final class WebSocketStockRepositoryImpl: StockLiveRepository, @unchecked Sendable {

    private var webSocket: WebSocketClient
    private let subject = PassthroughSubject<[Stock], Never>()
    private let stateActor = StockStateActor()
    private var cancellables = Set<AnyCancellable>()
    
    init(webSocket: WebSocketClient) {
        self.webSocket = webSocket
        self.bindWebSocket()
    }
    
    // MARK: - Bounded Buffer with Backpressure
    //
    // Strategy: The Combine pipeline below implements bounded buffering with backpressure:
    // 1. collect(.byTime) acts as the time-windowed buffer — accumulates all updates within 1 second
    // 2. Dictionary(grouping:) + .last deduplicates — keeps only the latest price per symbol
    // 3. Stale intermediate prices are discarded — a user never sees outdated prices
    //
    // This prevents UI thrashing from Finnhub's hundreds of updates/second while ensuring
    // the UI always shows the most recent price for each symbol.

    private func bindWebSocket() {
        webSocket.stockPublisher
            .collect(.byTime(RunLoop.main, .seconds(AppConstants.batchCollectionSeconds)))
            .map { updates in
                // Group by symbol and pick latest for each symbol
                ///Ensures only the latest update per symbol is processed.
                Dictionary(grouping: updates, by: \.symbol)
                    .compactMapValues { $0.last }
                    .values
            }
            .sink { [weak self] latestUpdates in
                for dto in latestUpdates {
                    self?.handle(dto)
                }
            }
            .store(in: &cancellables)
    }
    
    func observeStocks() -> AnyPublisher<[Stock], Error> {
        webSocket.connect()//Connect to web socket
        return subject.setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        subject.setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func subscribeToSymbols(_ symbols: [String]) {
        webSocket.subscribe(to: symbols)
    }
    
    private func handle(_ dto: StockFinnPriceDTO) {

        guard let symbol = dto.symbol else {
            AppLogger.warning("Missing symbol in DTO, skipping", category: AppLogger.webSocket)
            return
        }

        // Actor replaces the previous stocksQueue.sync { } pattern.
        // The compiler enforces that all access to stateActor's state
        // goes through `await`, eliminating data races at compile time.
        Task { [weak self] in
            guard let self else { return }
            let snapshot = await self.stateActor.snapshot()
            let oldPrice = snapshot.first(where: { $0.symbol == symbol })?.price ?? 0
            if let stock = dto.toDomainModel(previousPrice: oldPrice) {
                let allStocks = await self.stateActor.update(symbol: symbol, stock: stock)
                self.subject.send(allStocks)
            } else {
                AppLogger.error("Invalid StockDTO, could not convert to Stock: \(symbol)", category: AppLogger.webSocket)
            }
        }
    }
}
