//
//  NetworkService.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 13.02.2022.
//

import Alamofire

protocol Networkable {
    
    func request(complition: @escaping(Result<NetworkModel, Error>) -> Void)
}

final class NetworkService: Networkable {
    
    let url = "http://api.exchangeratesapi.io/latest?access_key=7e9f2e1f655a573e5189f16d2cb00a85"
    
    func request(complition completion: @escaping (Result<NetworkModel, Error>) -> Void) {
        AF.request(url).responseDecodable(of: NetworkModel.self) { responce in
            switch responce.result {
                
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
