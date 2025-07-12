//
//  Untitled.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//
import Combine
import Foundation

//This protocol defines a single requirement: stockPublisher, which is a Combine publisher that emits an array of Stock objects over time.
protocol StockStreamingServiceProtocol {
    var stockPublisher: AnyPublisher<[Stock], any Error> { get }
}

//This class mocks a real-time stock streaming service by simulating stock price updates at regular intervals.
//It conforms to the StockStreamingService protocol.
final class MockStockStreamingService: StockStreamingServiceProtocol {
    
    private var stocks: [Stock]
    
    private var timer: Timer.TimerPublisher
    
    //Stores Combine subscriptions to manage memory and cancel publishers when needed.
    private var cancellables = Set<AnyCancellable>()
    
    //A subject that acts as a bridge between internal logic and the public stockPublisher.
    private let subject = PassthroughSubject<[Stock], any Error>()
    
    //Exposes the subject as a read-only AnyPublisher, so consumers can subscribe to stock updates but can't send values
    var stockPublisher: AnyPublisher<[Stock], any Error> {
        subject.eraseToAnyPublisher()
    }
    
    //Initializes the timer to fire every 1.5 seconds (or custom interval).
    init(stocks: [Stock] = MockStockData.allStocks, interval: TimeInterval = 2.5) {
        self.timer = Timer.publish(every: interval, on: .main, in: .common)
        self.stocks = stocks
        subject.send(stocks) // Send initial snapshot
        setupTimer()
    }
    
    //Connects the timer and triggers simulatePriceChange() every time it fires.
    private func setupTimer() {
        timer
            .autoconnect()
            .sink { [weak self] _ in
                self?.simulatePriceChange()
            }
            .store(in: &cancellables)
    }
    
    private func simulatePriceChange() {
        stocks = stocks.map { stock in
            let change = Double.random(in: -2...1)
            let newPrice = max(stock.price + change, 0)
            return stock.updatedPrice(newPrice)
        }
        subject.send(stocks)
    }
}


