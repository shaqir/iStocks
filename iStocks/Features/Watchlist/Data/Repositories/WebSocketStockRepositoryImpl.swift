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
        if let webSocketClient = webSocket as? TwelveDataWebSocketClient {
            webSocketClient.stockPublisher
                .receive(on: RunLoop.main)
                .sink { [weak self] dto in
                    print("Received stock: \(dto.symbol ?? "NA") @ \(dto.price)")
                    self?.handle(dto)
                }
                .store(in: &cancellables)
        }
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

    private func handle(_ dto: StockDTO) {
        let oldPrice = currentStocks[dto.symbol ?? ""]?.price ?? 0
        if let stock = dto.toDomainModel(invested: oldPrice) {
            currentStocks[dto.symbol ?? ""] = stock
            subject.send(Array(currentStocks.values))
        }
    }
}
