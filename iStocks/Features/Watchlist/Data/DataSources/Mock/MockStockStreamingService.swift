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
    func start()
    func stop()
}

//This class mocks a real-time stock streaming service by simulating stock price updates at regular intervals.
//It conforms to the StockStreamingService protocol.
final class MockStockStreamingService: StockStreamingServiceProtocol {
    
    private var stocks: [Stock]
    
    private var timer: Timer.TimerPublisher
    
    //Stores Combine subscriptions to manage memory and cancel publishers when needed.
    private var cancellables = Set<AnyCancellable>()
    
    //A subject that acts as a bridge between internal logic and the public stockPublisher.
    //immediate snapshot to subscribers
    ///each new subscriber to immediately receive the latest snapshot (not wait for next emission):
    private let subject: CurrentValueSubject<[Stock], Error>
    
    //Exposes the subject as a read-only AnyPublisher, so consumers can subscribe to stock updates but can't send values
    
    // shared so multiple subscribers don’t retrigger simulatePriceChange()
    /// Only one timer/stream no matter how many subscribers
    ///Subscribers receive price changes without triggering new simulatePriceChange() calls
    var stockPublisher: AnyPublisher<[Stock], Error> {
        subject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private var timerCancellable: AnyCancellable?
    
    //Initializes the timer to fire every 1.5 seconds (or custom interval).
    init(stocks: [Stock] = MockStockData.allStocks, interval: TimeInterval = 1.5) {
        self.stocks = stocks
        self.subject = CurrentValueSubject(stocks) // immediate snapshot to subscribers
        self.timer = Timer.publish(every: interval, on: .main, in: .common)
    }
    
    func start() {
           guard timerCancellable == nil else { return } // prevent multiple timers
           timerCancellable = timer
               .autoconnect()
               .sink { [weak self] _ in
                   self?.simulatePriceChange()
               }
    }
    
    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
        subject.send(completion: .finished) // Prevents reuse after stop in unit tests
    }
    
    private func simulatePriceChange() {
        stocks = stocks.map { stock in
            let change = Double.random(in: -2...1)
            let newPrice = max(stock.price + change, 0)
            return stock.updatedPrice(newPrice)
        }
        print("[MockService] Emitting price updates for all mock stocks...")
        subject.send(stocks)
    }
}


