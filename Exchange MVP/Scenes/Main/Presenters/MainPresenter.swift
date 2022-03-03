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
    func fetchRates()
    func exchangeCurrency()
    
    func fetchRatesAndValuesFromTop()
    func fetchRatesAndValuesFromBottom()

    func saveTopIndex(_ topIndex: Int)
    func saveBottomIndex(_ bottomIndex: Int)
    func saveTopValue(_ topValue: Double?)
    func saveBottomValue(_ bottomValue: Double?)
}

// MARK: - Presenter
final class MainPresenter {
    
    weak var view: ViewProtocol?
    
    private let networkService: Networkable
    private var rates: RateModel?

    private var topIndex = 0 // индекс верхней ячейки
    private var bottomIndex = 0
    private var topValue: Double? //значение верхнего textField.
    private var bottomValue: Double? //значение нижнего textField.
    private var isTop = false
    
    private var myBalance: [AccountModel] = []
    
    init(networkService: Networkable) {
        self.networkService = networkService
        setUserDefaults()
        fetchUserDefaultsToAccount()
        
        let _ = Timer.scheduledTimer(timeInterval: 30,
                                     target: self,
                                     selector: #selector(timerMethod),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc func timerMethod() {
        loadData()
    }
}

// MARK: - PresenterProtocol Impl
extension MainPresenter: PresenterProtocol {
        
    func loadData() {
        
        networkService.request { result in
            switch result {
                
            case .success(let response):
                self.rates = response.rates
                self.updateCells()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
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
    
    func exchangeCurrency() {
        
        guard topValue != nil else {
            view?.showAlert(result: "Value is empty!")
            return
        }
        let topCurrency = myBalance[topIndex]
        let bottomCurrency = myBalance[bottomIndex]
        
        guard topIndex != bottomIndex else {
            view?.showAlert(result: "you are trying to exchange the same currency!")
            return
        }
        
        var resultForTopBalance = myBalance[topIndex].value - (topValue ?? 0)
        guard resultForTopBalance >= 0 else {
            view?.showAlert(result: "Not enought money!")
            return
        }
        resultForTopBalance = Double(round(100 * (resultForTopBalance)) / 100)
        var resultForBottomBalance = myBalance[bottomIndex].value + (bottomValue ?? 0)
        resultForBottomBalance = Double(round(100 * (resultForBottomBalance)) / 100)
        
        let secondValueRounded = Double(round(100 * (bottomValue ?? 0.0)) / 100)
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
    
    //метод считает введенное value по rates и обновляет нижний collectionView
    func fetchRatesAndValuesFromTop() {
        isTop = true
        //создаем объект верхней и нижней ячейки
        let topCurrency = myBalance[topIndex].currency
        let bottomCurrency = myBalance[bottomIndex].currency
        
        //определяем rate активной ячейки верхнего и нижнего view
        let fromRate = fetchRateValue(from: topCurrency)
        let toRate = fetchRateValue(from: bottomCurrency)
        
        let top = String(format: "%.2f", toRate / fromRate)
        let bottom = String(format: "%.2f", fromRate / toRate)
        
        let topRate = "1\(topCurrency.currencyCharacter) - \(top)\(bottomCurrency.currencyCharacter)"
        let bottomRate = "1\(bottomCurrency.currencyCharacter) - \(bottom)\(topCurrency.currencyCharacter)"
        
        let first = fetchViewModel(currentIndex: topIndex,
                                   currentRate: topRate,
                                   currentValue: topValue,
                                   isTop: true)
        
        if let topValue = topValue {
            bottomValue = topValue * (toRate / fromRate)
        } else {
            bottomValue = nil
        }
        
        let second = fetchViewModel(currentIndex: bottomIndex,
                                    currentRate: bottomRate,
                                    currentValue: bottomValue,
                                    isTop: false)
        
        let viewModel = ViewModel(first: first, second: second)

        view?.updateSecondCollectionView(viewModel)
    }
    
    //метод считает введенное value по rates и обновляет верхний collectionView
    func fetchRatesAndValuesFromBottom() {
        //создаем объект верхней и нижней ячейки
        isTop = false
        let topCurrency = myBalance[topIndex].currency
        let bottomCurrency = myBalance[bottomIndex].currency
        
        //определяем rate активной ячейки верхнего и нижнего view
        let fromRate = fetchRateValue(from: topCurrency)
        let toRate = fetchRateValue(from: bottomCurrency)
        
        let top = String(format: "%.2f", toRate / fromRate)
        let bottom = String(format: "%.2f", fromRate / toRate)
        
        let topRate = "1\(topCurrency.currencyCharacter) - \(top)\(bottomCurrency.currencyCharacter)"
        let bottomRate = "1\(bottomCurrency.currencyCharacter) - \(bottom)\(topCurrency.currencyCharacter)"
        
        if let bottomValue = bottomValue {
            topValue = bottomValue * (fromRate / toRate)
            self.bottomValue = bottomValue
        } else {
            topValue = nil
        }
        
        let first = fetchViewModel(currentIndex: topIndex,
                                   currentRate: topRate,
                                   currentValue: topValue,
                                   isTop: true)
    
        let second = fetchViewModel(currentIndex: bottomIndex,
                                    currentRate: bottomRate,
                                    currentValue: bottomValue,
                                    isTop: false)
        
        let viewModel = ViewModel(first: first, second: second)

        view?.updateFirstCollectionView(viewModel)
    }
    
    //метод обновляет все collectionView и расчитывает rates, при скролле
    func fetchRates() {
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
        
        //собираем модель для ячеек CollectionView
        let first = fetchViewModel(currentIndex: topIndex, currentRate: topRate, isTop: true)
        let second = fetchViewModel(currentIndex: bottomIndex, currentRate: bottomRate, isTop: false)
        
        let viewModel = ViewModel(first: first, second: second)
        
        topValue = nil
        bottomValue = nil
        view?.updateView(viewModel, topRate)
    }
    
    func saveTopIndex(_ topIndex: Int) {
        self.topIndex = topIndex
    }
    
    func saveBottomIndex(_ bottomIndex: Int) {
        self.bottomIndex = bottomIndex
    }
    
    func saveTopValue(_ topValue: Double?) {
        self.topValue = topValue
    }
    
    func saveBottomValue(_ bottomValue: Double?) {
        self.bottomValue = bottomValue
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
    
    func updateCells() {
        //создаем объект верхней и нижней ячейки
        let topCurrency = myBalance[topIndex].currency
        let bottomCurrency = myBalance[bottomIndex].currency
        
        //определяем rate активной ячейки верхнего и нижнего view
        let fromRate = fetchRateValue(from: topCurrency)
        let toRate = fetchRateValue(from: bottomCurrency)
        
        let top = String(format: "%.2f", toRate / fromRate)
        let bottom = String(format: "%.2f", fromRate / toRate)
        
        let topRate = "1\(topCurrency.currencyCharacter) - \(top)\(bottomCurrency.currencyCharacter)"
        let bottomRate = "1\(bottomCurrency.currencyCharacter) - \(bottom)\(topCurrency.currencyCharacter)"
        
        if isTop {
            if let topValue = topValue {
                bottomValue = topValue * (toRate / fromRate)
            } else {
                bottomValue = nil
            }
        } else {
            if let bottomValue = bottomValue {
                topValue = bottomValue * (fromRate / toRate)
                self.bottomValue = bottomValue
            } else {
                topValue = nil
            }
        }
        
        let first = fetchViewModel(currentIndex: topIndex,
                                   currentRate: topRate,
                                   currentValue: topValue,
                                   isTop: true)
        
        let second = fetchViewModel(currentIndex: bottomIndex,
                                   currentRate: bottomRate,
                                   currentValue: bottomValue,
                                   isTop: false)
        
        let viewModel = ViewModel(first: first, second: second)
        
        view?.updateView(viewModel, topRate)
    }
    // собираем пустую модель, при загрузки rates
//    func updateCells() {
//        let first = myBalance.map { account -> CellModel in
//            let cellModel = CellModel(balance: "You have: \(account.value)\(account.currency.currencyCharacter)",
//                                      rate: "1\(account.currency.currencyCharacter) = 1\(account.currency.currencyCharacter)",
//                                      currency: account.currency.currencyName,
//                                      value: nil,
//                                      isTop: true)
//            return cellModel
//        }
//
//        let second = myBalance.map { account -> CellModel in
//            let cellModel = CellModel(balance: "You have: \(account.value)\(account.currency.currencyCharacter)",
//                                      rate: "1\(account.currency.currencyCharacter) = 1\(account.currency.currencyCharacter)",
//                                      currency: account.currency.currencyName,
//                                      value: nil,
//                                      isTop: false)
//            return cellModel
//        }
//
//        let viewModel = ViewModel(first: first,
//                                  second: second)
//        let topRate =  "1€ - 1.00€"
//        view?.updateView(viewModel, topRate)
//    }
    
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


