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
    private var webSocket: WebSocketClient2
    private var subject = PassthroughSubject<[Stock], Never>()
    private var currentStocks: [String: Stock] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init(webSocket: WebSocketClient2) {
        self.webSocket = webSocket
        self.bindWebSocket()
    }
    
    private func bindWebSocket() {
        print("Binding stockPublisher...")

        webSocket.stockPublisher
            .collect(.byTime(RunLoop.main, .seconds(1)))
            .map { updates in
                // Group by symbol and pick latest for each symbol
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
        webSocket.connect()
        return subject.setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        subject.setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func subscribeToSymbols(_ symbols: [String]) {
        webSocket.subscribe(to: symbols)
    }
    
    private func handle(_ dto: StockPriceDTO2) {
        
        guard let symbol = dto.symbol else {
            print("⚠️ Missing symbol in DTO, skipping: \(dto)")
            return
        }

        let price = dto.price
        print("Handling DTO: symbol=\(symbol), price=\(price)")

        let oldPrice = currentStocks[symbol]?.price ?? 0

        if let stock = dto.toDomainModel(invested: oldPrice) {
            currentStocks[symbol] = stock
            subject.send(Array(currentStocks.values))
        } else {
            print("⚠️ Invalid StockDTO, could not convert to Stock: \(dto)")
        }
    }
    
}
