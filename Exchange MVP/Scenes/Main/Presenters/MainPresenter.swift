//
//  MainPresenter.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 09.02.2022.
//

import Foundation


// MARK: - PresenterProtocol
protocol PresenterProtocol {
    func loadData()
    func fetchRates(topIndex: Int, bottomIndex: Int)
    func fetch(topIndex: Int, bottomIndex: Int, topValue: Double)
}

// MARK: - Presenter
final class MainPresenter {
        
    weak var view: ViewProtocol?
    
    private let networkService: Networkable
    private var rates: RateModel?
    
    private var myBalance = [
        AccountModel(value: 100, currency: .EUR),
        AccountModel(value: 100, currency: .USD),
        AccountModel(value: 100, currency: .GBP),
    ]
    
    init(networkService: Networkable) {
        self.networkService = networkService
    }
}

// MARK: - PresenterProtocol Impl
extension MainPresenter: PresenterProtocol {
    
    func fetch(topIndex: Int, bottomIndex: Int, topValue: Double) {
        let topCurrency = myBalance[topIndex].currency
        let bottomCurrency = myBalance[bottomIndex].currency
        
        let fromRate: Double
        
        switch topCurrency {
        case .EUR:
            fromRate = rates?.EUR ?? 0
        case .USD:
            fromRate = rates?.USD ?? 0
        case .GBP:
            fromRate = rates?.GBP ?? 0
        }

        
        let toRate: Double
        
        switch bottomCurrency {
        case .EUR:
            toRate = rates?.EUR ?? 0
        case .USD:
            toRate = rates?.USD ?? 0
        case .GBP:
            toRate = rates?.GBP ?? 0
        }
        
        let top = String(format: "%.2f", toRate / fromRate)
        let bottom = String(format: "%.2f", fromRate / toRate)
        
        let topRate = "1\(topCurrency.currencyCharacter) - \(top)\(bottomCurrency.currencyCharacter)"
        let bottomRate = "1\(bottomCurrency.currencyCharacter) - \(bottom)\(topCurrency.currencyCharacter)"
        print(topRate)
        print(bottomRate)
        
        let first = myBalance.enumerated().map { (index, balance) -> CellModel in
            var rate = ""
            var value = 0.0
            if index == topIndex {
                rate = topRate
                value = topValue
            }
            let cellModel = CellModel(balance: "You have: \(balance.value)",
                                      rate: rate,
                                      currency: balance.currency.currencyName,
                                      value: value)
            return cellModel
        }
        
        let second = myBalance.enumerated().map { (index, balance) -> CellModel in
            var rate = ""
            var value: Double? = nil
            if index == bottomIndex {
                rate = bottomRate
                value = topValue * (toRate / fromRate)
            }
            let cellModel = CellModel(balance: "You have: \(balance.value)",
                                      rate: rate,
                                      currency: balance.currency.currencyName,
                                      value: value)
            return cellModel
        }
        
        let viewModel = ViewModel(first: first, second: second)
        
        view?.updateView(viewModel)

    }

    func fetchRates(topIndex: Int, bottomIndex: Int) {
        let topCurrency = myBalance[topIndex].currency
        let bottomCurrency = myBalance[bottomIndex].currency
        
        let fromRate: Double
        
        switch topCurrency {
        case .EUR:
            fromRate = rates?.EUR ?? 0
        case .USD:
            fromRate = rates?.USD ?? 0
        case .GBP:
            fromRate = rates?.GBP ?? 0
        }

        
        let toRate: Double
        
        switch bottomCurrency {
        case .EUR:
            toRate = rates?.EUR ?? 0
        case .USD:
            toRate = rates?.USD ?? 0
        case .GBP:
            toRate = rates?.GBP ?? 0
        }
        
        let top = String(format: "%.2f", toRate / fromRate)
        let bottom = String(format: "%.2f", fromRate / toRate)
        
        let topRate = "1\(topCurrency.currencyCharacter) - \(top)\(bottomCurrency.currencyCharacter)"
        let bottomRate = "1\(bottomCurrency.currencyCharacter) - \(bottom)\(topCurrency.currencyCharacter)"
        print(topRate)
        print(bottomRate)
        
        let first = myBalance.enumerated().map { (index, balance) -> CellModel in
            var rate = ""
            if index == topIndex {
                rate = topRate
            }
            let cellModel = CellModel(balance: "You have: \(balance.value)",
                                      rate: rate,
                                      currency: balance.currency.currencyName,
                                      value: nil)
            return cellModel
        }
        
        let second = myBalance.enumerated().map { (index, balance) -> CellModel in
            var rate = ""
            if index == bottomIndex {
                rate = bottomRate
            }
            let cellModel = CellModel(balance: "You have: \(balance.value)",
                                      rate: rate,
                                      currency: balance.currency.currencyName,
                                      value: nil)
            return cellModel
        }
        
        let viewModel = ViewModel(first: first, second: second)
        
        view?.updateView(viewModel)
    }
    

    func loadData() {
        networkService.request(target: EndPoint.fetchRates, type: NetworkModel.self) { [weak self] result in
            switch result {
            case .success(let response):
                self?.rates = response.rates
                self?.updateCells()
                print(response.rates)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - Private methods
private extension MainPresenter {
    
    func updateCells() {
        let first = myBalance.map { account -> CellModel in
            let cellModel = CellModel(balance: "You have: \(account.value)",
                                      rate: "1\(account.currency.currencyCharacter) = 1\(account.currency.currencyCharacter)",
                                      currency: account.currency.currencyName,
                                      value: nil)
            return cellModel
        }
        let viewModel = ViewModel(first: first,
                                  second: first)
        view?.updateView(viewModel)
    }
}


