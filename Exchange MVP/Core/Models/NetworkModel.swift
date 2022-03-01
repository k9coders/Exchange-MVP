//
//  NetworkModel.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 09.02.2022.
//

struct NetworkModel: Decodable {
    let rates: RateModel
}

struct RateModel: Decodable {
    let EUR: Double
    let USD: Double
    let GBP: Double
}
