//
//  Untitled.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 17/09/2025.
//

import SwiftUI
import Combine

class NetworkingManager {
    
    enum NetworkingError: LocalizedError {
        case badURLResponse(url: URL)
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .badURLResponse(url: let url): return "[🔥] Bad response from URL :\(url)"
            case .unknown: return "[⚠️] Unknown Error Occured"
            }
        }
    }
    
    // Made with this func so we dont write same code again(using this as shorcut code)
    // AnyPublisher makes it generic(special feature of combine)
    
    // Note: dataTaskPublisher by default on subscribe BG thread (.subscribe is useless to write just written for understanding purposes)
    static func download(url: URL) -> AnyPublisher<Data, Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .subscribe(on: DispatchQueue.global(qos: .default))
            .tryMap { try handleURLResponse(output: $0, url: url) }
            .retry(3) // only if we dont receive data try again
            .eraseToAnyPublisher()
    }
    
    static func handleURLResponse(output: URLSession.DataTaskPublisher.Output, url: URL) throws -> Data {
        guard let response = output.response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 else {
            throw NetworkingError.badURLResponse(url: url)
        }
        return output.data
    }
    
    static func handleCompletion(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            break
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    
    static func buildUrl() -> URL? {
        // Use URLComponents to build the URL with query parameters
                guard var urlComponents = URLComponents(string: "https://api.coingecko.com/api/v3/coins/markets") else {
                    print("Invalid base URL string.")
                    return nil
                }
                
        // Building full url for this api(Depends on api)
                urlComponents.queryItems = [
                    URLQueryItem(name: "vs_currency", value: "usd"),
                    URLQueryItem(name: "order", value: "market_cap_desc"),
                    URLQueryItem(name: "per_page", value: "100"),
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "sparkline", value: "true"),
                    URLQueryItem(name: "price_change_percentage", value: "24h")
                ]
        return urlComponents.url
    }
}

