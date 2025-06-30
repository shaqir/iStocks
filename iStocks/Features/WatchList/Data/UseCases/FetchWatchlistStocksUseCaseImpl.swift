import Combine

final class FetchWatchlistStocksUseCaseImpl: FetchWatchlistStocksUseCase {
    private let repository: StockRepository

    init(repository: StockRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[Stock], Error> {
        repository.getWatchlistStocks()
    }
}