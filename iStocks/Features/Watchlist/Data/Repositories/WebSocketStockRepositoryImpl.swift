//
//  WebSocketStockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-17.
//
// WebSocketStockRepository.swift

import Foundation
import Combine

final class WebSocketStockRepositoryImpl: StockLiveRepository {
    
    private var webSocket: WebSocketClient
    private var subject = PassthroughSubject<[Stock], Never>()
    private var currentStocks: [String: Stock] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init(webSocket: WebSocketClient) {
        self.webSocket = webSocket
        self.bindWebSocket()
    }
    
    private func bindWebSocket() {
        print("Binding WebSocket to stockPublisher...")
        webSocket.stockPublisher
        ///Batches incoming DTOs per 1 second. Prevents excessive UI updates.
            .collect(.byTime(RunLoop.main, .seconds(1)))
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
            print("Missing symbol in DTO, skipping: \(dto)")
            return
        }
        let price = dto.price
        print("Handling DTO: symbol=\(symbol), price=\(price)")
        let oldPrice = currentStocks[symbol]?.price ?? 0
        if let stock = dto.toDomainModel(invested: oldPrice) {
            currentStocks[symbol] = stock
            subject.send(Array(currentStocks.values))
        } else {
            print("Invalid StockDTO, could not convert to Stock: \(dto)")
        }
    }
}
