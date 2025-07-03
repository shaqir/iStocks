import Combine

//Abstracts stock-fetching logic
protocol StockRepository {
    func observeStocks() -> AnyPublisher<[Stock], Error>
}
