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
    func setUserDefaults()
    func fetchRates(topIndex: Int, bottomIndex: Int)
    func fetchRatesAndValues(topIndex: Int, bottomIndex: Int, topValue: Double)
    func exchangeCurrency(topValue: Double?, topIndex: Int, bottomIndex: Int)
}

// MARK: - Presenter
final class MainPresenter {
    
    weak var view: ViewProtocol?
    
    private let networkService: Networkable
    private var rates: RateModel?
    private var secondValue: Double?
    
    private var myBalance: [AccountModel] = []
    
    init(networkService: Networkable) {
        self.networkService = networkService
        setUserDefaults()
        fetchUserDefaultsToAccount()
    }
}

// MARK: - PresenterProtocol Impl
extension MainPresenter: PresenterProtocol {
    func exchangeCurrency(topValue: Double?, topIndex: Int, bottomIndex: Int) {
        
        guard topValue != nil else {
            view?.showAlert(result: "Value is empty!")
            return
        }
        let topCurrency = myBalance[topIndex]
        let bottomCurrency = myBalance[bottomIndex]
        print("\(topCurrency.currency.currencyName)  \(bottomCurrency.currency.currencyName)")
        
        var resultForTopBalance = myBalance[topIndex].value - (topValue ?? 0)
        guard resultForTopBalance >= 0 else {
            view?.showAlert(result: "Not enought money!")
            return
        }
        resultForTopBalance = Double(round(100 * (resultForTopBalance)) / 100)
        var resultForBottomBalance = myBalance[bottomIndex].value + (secondValue ?? 0)
        resultForBottomBalance = Double(round(100 * (resultForBottomBalance)) / 100)
        print("from \(resultForTopBalance) to \(resultForBottomBalance)")
        
        let secondValueRounded = Double(round(100 * (secondValue ?? 0.0)) / 100)
        let result = """
        Receipt \(bottomCurrency.currency.currencyCharacter)\(secondValueRounded) to account \(bottomCurrency.currency.currencyName).
        Avilible balance: \(myBalance[bottomIndex].value)
        Avilible accounts:
        \(myBalance[0].currency.currencyCharacter)\(myBalance[0].value)
        \(myBalance[1].currency.currencyCharacter)\(myBalance[1].value)
        \(myBalance[2].currency.currencyCharacter)\(myBalance[2].value)
        """
        
        UserDefaults.standard.set(resultForTopBalance, forKey: topCurrency.currency.currencyName)
        UserDefaults.standard.set(resultForBottomBalance, forKey: bottomCurrency.currency.currencyName)
        fetchUserDefaultsToAccount()
        
        view?.showAlert(result: result)
    }
    
    // устанавливаем значения userDefaults
    func setUserDefaults() {
        let balance = UserDefaults.standard.bool(forKey: "isFirstStart")
        if balance == false {
            UserDefaults.standard.set(100.0, forKey: "EUR")
            UserDefaults.standard.set(100.0, forKey: "USD")
            UserDefaults.standard.set(100.0, forKey: "GBP")
            UserDefaults.standard.set(true, forKey: "isFirstStart")
        }
    }
    
    //метод считает введенное value по rates и обновляет нижний collectionView
    func fetchRatesAndValues(topIndex: Int, bottomIndex: Int,  topValue: Double) {
        //создаем объект верхней и нижней ячейки
        let topCurrency = myBalance[topIndex].currency
        let bottomCurrency = myBalance[bottomIndex].currency
        
        //определяем rate активной ячейки верзнего и нижнего view
        let fromRate = fetchRateValue(from: topCurrency)
        let toRate = fetchRateValue(from: bottomCurrency)
        
        let top = String(format: "%.2f", toRate / fromRate)
        let bottom = String(format: "%.2f", fromRate / toRate)
        
        let topRate = "1\(topCurrency.currencyCharacter) - \(top)\(bottomCurrency.currencyCharacter)"
        let bottomRate = "1\(bottomCurrency.currencyCharacter) - \(bottom)\(topCurrency.currencyCharacter)"
        print(topRate)
        print(bottomRate)
        
        let first = fetchViewModel(currentIndex: topIndex,
                                   currentRate: topRate,
                                   currentValue: topValue,
                                   isTop: true)
        self.secondValue = topValue * (toRate / fromRate)
        let second = fetchViewModel(currentIndex: bottomIndex,
                                    currentRate: bottomRate,
                                    currentValue: secondValue,
                                    isTop: false)
        
        let viewModel = ViewModel(first: first, second: second)
        
        view?.updateSecondCollectionView(viewModel)
    }
    
    //метод обновляет все collectionView и расчитывает rates, при скролле
    func fetchRates(topIndex: Int, bottomIndex: Int) {
        //создаем объект верзней и нижней ячейки
        let topCurrency = myBalance[topIndex].currency
        let bottomCurrency = myBalance[bottomIndex].currency
        
        //определяем rate активной ячейки верзнего и нижнего view
        let fromRate = fetchRateValue(from: topCurrency)
        let toRate = fetchRateValue(from: bottomCurrency)
        
        let top = String(format: "%.2f", toRate / fromRate)
        let bottom = String(format: "%.2f", fromRate / toRate)
        
        let topRate = "1\(topCurrency.currencyCharacter) - \(top)\(bottomCurrency.currencyCharacter)"
        let bottomRate = "1\(bottomCurrency.currencyCharacter) - \(bottom)\(topCurrency.currencyCharacter)"
        
        //собираем модель для ячеек CollectionView
        let first = fetchViewModel(currentIndex: topIndex, currentRate: topRate, isTop: true)
        let second = fetchViewModel(currentIndex: bottomIndex, currentRate: bottomRate, isTop: false)
        
        let viewModel = ViewModel(first: first, second: second)
        
        view?.updateView(viewModel, topRate)
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
    
    //заполнить массив AcccauntModel данными из UserDefaults
    func fetchUserDefaultsToAccount() {
        myBalance = [
            AccountModel(value: UserDefaults.standard.double(forKey: "EUR"), currency: .EUR),
            AccountModel(value: UserDefaults.standard.double(forKey: "USD"), currency: .USD),
            AccountModel(value: UserDefaults.standard.double(forKey: "GBP"), currency: .GBP),
        ]
    }
    
    // собираем пустую модель, при загрузки rates
    func updateCells() {
        let first = myBalance.map { account -> CellModel in
            let cellModel = CellModel(balance: "You have: \(account.value)\(account.currency.currencyCharacter)",
                                      rate: "1\(account.currency.currencyCharacter) = 1\(account.currency.currencyCharacter)",
                                      currency: account.currency.currencyName,
                                      value: nil,
                                      isTop: true)
            return cellModel
        }
        
        let second = myBalance.map { account -> CellModel in
            let cellModel = CellModel(balance: "You have: \(account.value)\(account.currency.currencyCharacter)",
                                      rate: "1\(account.currency.currencyCharacter) = 1\(account.currency.currencyCharacter)",
                                      currency: account.currency.currencyName,
                                      value: nil,
                                      isTop: false)
            return cellModel
        }
        
        let viewModel = ViewModel(first: first,
                                  second: second)
        let topRate =  "1€ - 1.00€"
        view?.updateView(viewModel, topRate)
    }
    
    // в зависимости от валюты возвращаем значение rate
    func fetchRateValue(from currency: CurrencyType) -> Double {
        
        switch currency {
        case .EUR:
            return rates?.EUR ?? 0
        case .USD:
            return rates?.USD ?? 0
        case .GBP:
            return rates?.GBP ?? 0
        }
    }
    
    // собираем модель, с заполненными видимыми ячейками
    func fetchViewModel(currentIndex: Int,
                        currentRate: String,
                        currentValue: Double? = nil, isTop: Bool) -> [CellModel] {
        let result = myBalance.enumerated().map { (index, balance) -> CellModel in
            var rate = ""
            var value: Double? = nil
            if index == currentIndex {
                rate = currentRate
                value = currentValue
            }
            let cellModel = CellModel(balance: "You have: \(balance.value)\(balance.currency.currencyCharacter)",
                                      rate: rate,
                                      currency: balance.currency.currencyName,
                                      value: value,
                                      isTop: isTop)
            return cellModel
        }
        return result
    }
}


