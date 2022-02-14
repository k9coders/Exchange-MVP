//
//  NetworkService.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 13.02.2022.
//

import Alamofire

protocol Networkable {
    func request<T: Decodable>(target: TargetType, type: T.Type, completion: @escaping (Result<T, Error>) -> Void)
}

final class NetworkService: Networkable {
    
    private func fetchParametersAndEncoding(task: Task) -> (parameters: [String: Any], encoding: ParameterEncoding) {
        switch task {
        case .requestPlain:
            return (parameters: [:], encoding: URLEncoding.default)
        case .requestParameners(let parameters, let encoding):
            return (parameters: parameters, encoding: encoding)
        }
    }
    
    func request<T: Decodable>(target: TargetType, type: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        let error = NSError(domain: "My Error", code: 777, userInfo: nil)
        let request = AF.request(target.baseUrl + target.path,
                                 method: Alamofire.HTTPMethod(rawValue: target.method.rawValue),
                                 parameters: fetchParametersAndEncoding(task: target.task).parameters,
                                 encoding: fetchParametersAndEncoding(task: target.task).encoding,
                                 headers: Alamofire.HTTPHeaders(target.headers ?? [:]))
        request.responseJSON { response in
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(error))
                return
            }
            
            switch statusCode {
            case 200...210:
                guard let jsonResponse = try? response.result.get() else {
                    completion(.failure(error))
                    return
                }
                guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []) else {
                    completion(.failure(error))
                    return
                }
                guard let result = try? JSONDecoder().decode(type, from: jsonData) else {
                    completion(.failure(error))
                    return
                }
                completion(.success(result))
//                do {
//                    let result = try JSONDecoder().decode(type, from: jsonData)
//                    completion(.success(result))
//                } catch {
//                    completion(.failure(error))
//                }
            default:
                completion(.failure(error))
                break
            }
        }
    }
}

// // MARK: -
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum Task {
    case requestPlain
    case requestParameners(parameters: [String: Any],
                           encoding: ParameterEncoding)
}

protocol TargetType {
    var headers: [String: String]? { get }
    var baseUrl: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var task: Task { get }
    var parameters: [String: Any]? { get }
}


// MARK: -
enum EndPoint {
    case fetchRates
    case secondRequest
}

extension EndPoint: TargetType {
    
    var headers: [String : String]? {
        switch self {
        case .fetchRates,
             .secondRequest:
            return nil
        }
    }
    
    // "http://api.exchangeratesapi.io/latest?access_key=7e9f2e1f655a573e5189f16d2cb00a85"
    var baseUrl: String {
        switch self {
        case .fetchRates,
             .secondRequest:
            return "http://api.exchangeratesapi.io"
        }
    }
    
    var path: String {
        switch self {
        case .fetchRates:
            return "/latest"
        case .secondRequest:
            return "/top"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .fetchRates,
             .secondRequest:
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .fetchRates:
            return .requestParameners(parameters: parameters ?? [:],
                                      encoding: URLEncoding())
        case .secondRequest:
            return .requestPlain
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case .fetchRates:
            return ["access_key": "7e9f2e1f655a573e5189f16d2cb00a85"]
        case .secondRequest:
            return nil
        }
    }
}
