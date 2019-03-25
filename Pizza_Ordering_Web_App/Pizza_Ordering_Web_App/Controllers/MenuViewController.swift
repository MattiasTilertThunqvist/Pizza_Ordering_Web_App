//
//  MenuViewController.swift
//  Pizza_Ordering_Web_App
//
//  Created by Mattias Tilert Thunqvist on 2019-01-31.
//  Copyright © 2019 Mattias Tilert Thunqvist. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    // MARK: Properties
    
    var restaurant: Restaurant!
    var menu: [MenuItem] = []
    var categories: [String] = []
    var cart: [Cart] = [] {
        didSet {
            handleCartButton()
        }
    }
    var dismissProtocol: DismissProtocol!
    let menuCellIdentifier = "MenuItemTableViewCell"
    let animationDuration = 0.3
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cartContainerView: UIView!
    @IBOutlet weak var nrOfItemsLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var cartTapView: UIView!
    
    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getMenu()
        setup()
        setupTableView()
        registerNibs()
    }
}

// MARK: Setup

private extension MenuViewController {
    
    func setup() {
        title = restaurant.name
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(goToCart))
        cartTapView.addGestureRecognizer(tapGesture)
        handleCartButton()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    func registerNibs() {
        let cellNib = UINib(nibName: menuCellIdentifier, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: menuCellIdentifier)
    }
    
    func getMenu() {
        let loadingViewController = LoadingViewController()
        add(loadingViewController)
        
        DataController.sharedInstance.getMenuForRestaurant(with: restaurant.id) { (menu, error) in
            loadingViewController.remove()
            
            if error != nil {
                let alert = UIAlertController(title: "Kunde inte hämta meny", message: "", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Okej", style: .default, handler: nil)
                alert.addAction(alertAction)
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            } else if let menu = menu {
                for item in menu {
                    if !self.categories.contains(item.category) {
                        self.categories.append(item.category)
                    }
                }
                
                self.menu = menu
                self.sortMenuByRank()
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
}

// MARK: TableView

extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categories[section]
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = .pizzaRegularFont(withSize: 20)
            header.textLabel?.textColor = .foodlyColor(.white)
            header.backgroundView?.backgroundColor = .foodlyColor(.green)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let menuItemsInCategory = getMenuItemsIn(category: categories[section])
        return menuItemsInCategory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menuItemsInCategory = getMenuItemsIn(category: categories[indexPath.section])
        let menuItem = menuItemsInCategory[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: menuCellIdentifier) as! MenuItemTableViewCell
        cell.setName(to: menuItem.name)
        cell.setPrice(to: menuItem.price)
        cell.setDescription(to: menuItem.topping?.joined(separator: ", ") ?? "")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = StoryboardInstance.home
        if let viewController = storyboard.instantiateViewController(withIdentifier: "AddToCartViewController") as? AddToCartViewController {
            
            let allMenuItemsInCategory = getMenuItemsIn(category: categories[indexPath.section])
            let selectedMenuItem = allMenuItemsInCategory[indexPath.row]
            viewController.menuItem = selectedMenuItem
            viewController.restaurant = restaurant
            viewController.addToCartProtocol = self
            viewController.modalPresentationStyle = .overCurrentContext
            present(viewController, animated: false, completion: nil)
        }
    }
}

// MARK: Helpers

private extension MenuViewController {
    
    func sortMenuByRank() {
        menu.sort { (item1, item2) -> Bool in
            if let rank1 = item1.rank, let rank2 = item2.rank {
                return item1.category == item2.category && rank1 < rank2
            }
            
            return false
        }
    }
    
    func getMenuItemsIn(category: String) -> [MenuItem] {
        return menu.filter({ $0.category == category })
    }
}

// MARK: Cart

private extension MenuViewController {
    
    func handleCartButton() {
        setCartButtonText()
        cart.isEmpty ? hideCartButton(withAnimation: false) : showCartButton()
    }
    
    func showCartButton() {
        tableView.contentInset.bottom = cartContainerView.frame.height
        
        UIView.animate(withDuration: animationDuration) {
            self.cartContainerView.transform = .identity
            self.cartTapView.transform = .identity
        }
    }
    
    func hideCartButton(withAnimation animation: Bool) {
        tableView.contentInset.bottom = 0.0
        let timeInterval = animation ? animationDuration : 0.0
        
        UIView.animate(withDuration: timeInterval, animations: {
            let transformation = CGAffineTransform(translationX: 0,
                                                   y: self.view.bounds.maxY)
            self.cartContainerView.transform = transformation
            self.cartTapView.transform = transformation
        })
    }
    
    func setCartButtonText() {
        let quantity = Cart.quantityOfItems(in: cart)
        let itemString = quantity > 1 ? "varor" : "vara"
        nrOfItemsLabel.text = "\(quantity) \(itemString) i varukorgen"
        
        priceLabel.text = "\(Cart.totalPriceOfItems(in: cart)) kr"
        descriptionLabel.text = "Gå till varukorgen"
    }
    
    @objc func goToCart() {
        let storyboard = StoryboardInstance.home
        if let viewController = storyboard.instantiateViewController(withIdentifier: "CartViewController") as? CartViewController {
            viewController.restaurant = restaurant
            viewController.cart = cart
            viewController.updateCartProtocol = self
            viewController.dismissProtocol = dismissProtocol
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: UpdateCartProtocol

extension MenuViewController: UpdateCartProtocol {
    
    func addToCart(_ menuItem: MenuItem, quantity: Int) {
        if let index = cart.firstIndex(where: { $0.menuItem.id == menuItem.id }) {
            cart[index].quantity += quantity
        } else {
            let newItem = Cart(menuItem: menuItem, quantity: quantity)
            cart.append(newItem)
        }
    }
    
    func removeFromCart(_ menuItem: MenuItem) {
        cart.removeAll(where: { $0.menuItem.id == menuItem.id })
    }
}
