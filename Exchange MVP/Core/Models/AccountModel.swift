//
//  AccountModel.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 14.02.2022.
//

struct AccountModel {
    var value: Double
    let currency: CurrencyType
}

enum CurrencyType: Int {
    case EUR = 0
    case USD = 1
    case GBP = 2
    
    var currencyName: String {
        switch self {
        case .EUR:
            return "EUR"
        case .USD:
            return "USD"
        case .GBP:
            return "GBP"
        }
    }
    
    var currencyCharacter: String {
        switch self {
        case .EUR:
            return "€"
        case .USD:
            return "$"
        case .GBP:
            return "£"
        }
    }
}
