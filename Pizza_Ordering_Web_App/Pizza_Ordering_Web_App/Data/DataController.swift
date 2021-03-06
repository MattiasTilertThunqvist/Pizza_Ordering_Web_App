//
//  DataController.swift
//  Pizza_Ordering_Web_App
//
//  Created by Mattias Tilert Thunqvist on 2019-11-10.
//  Copyright © 2019 Mattias Tilert Thunqvist. All rights reserved.
//

import Foundation

class DataController {
    
    // MARK: Properties
    
    private static let urlString = "https://private-130ed-foodlyapp.apiary-mock.com/"
    private static let decoder = JSONDecoder()
    
    // MARK: Restarurants
    
    static func getRestaurants(completion: @escaping (Result<[Restaurant], Error>) -> ()) {
        let url = URL(string: urlString + "restaurants/")!
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                }
                
                fatalError("Data and error should never both be nil")
            }
            
            let result = Result(catching: {
                try decoder.decode([Restaurant].self, from: data)
            })
            
            completion(result)
        }.resume()
    }
    
    // MARK: Menu
    
    static func getMenu(restaurantId id: Int, completion: @escaping (Result<Menu, Error>) -> ()) {
        let url = URL(string: urlString + "restaurants/\(id)/menu")!

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                }
                
                fatalError("Data and error should never both be nil")
            }
            
            do {
                let menuItems = try JSONDecoder().decode([MenuItem].self, from: data)
                var menu = Menu(items: menuItems)
                menu.sortMenuByRank()
                completion(.success(menu))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: Order
    
    static func createOrder(restaurantId: Int, cart: [CartItem], completion: @escaping (_ order: Order?, _ error: Error?) -> ()) {
        let url = URL(string: urlString + "orders/createorder/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let orderDetails = cart.map { OrderDetails.init(menuItemId: $0.menuItem.id, quantity: $0.quantity) }
        let newOrder = NewOrder(orderDetails: orderDetails, restuarantId: restaurantId)
        
        do {
            let jsonData = try JSONEncoder().encode(newOrder)
            request.httpBody = jsonData
        } catch {
            completion(nil, error)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            do {
                var order = try JSONDecoder().decode(Order.self, from: data)
                order.cart = cart
                order.restuarantId = newOrder.restuarantId
                completion(order, nil)
            } catch let jsonError {
                completion(nil, jsonError)
            }
        }.resume()
    }
    
    static func getOrders(completion: @escaping (Result<[Order], Error>) -> ()) {
        let url = URL(string: urlString + "orders/")!
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                }
                
                fatalError("Data and error should never both be nil")
            }
            
            let result = Result(catching: {
                try decoder.decode([Order].self, from: data)
            })
            
            completion(result)
        }.resume()
    }
}


