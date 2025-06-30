import Combine

//Abstracts stock-fetching logic
protocol StockRepository {
    func getWatchlistStocks() -> AnyPublisher<[Stock], Error>
}
