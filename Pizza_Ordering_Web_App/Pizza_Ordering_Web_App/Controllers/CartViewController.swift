//
//  CartViewController.swift
//  Pizza_Ordering_Web_App
//
//  Created by Mattias Tilert Thunqvist on 2019-10-12.
//  Copyright © 2019 Mattias Tilert Thunqvist. All rights reserved.
//

import UIKit

class CartViewController: UIViewController {
    
    // MARK: Properties
    
    var restaurant: Restaurant!
    var cart: [CartItem] = []
    var updateCartProtocol: UpdateCartProtocol!
    var dismissProtocol: DismissProtocol!
    let animationDuration = 0.3
    
    // MARK: UI components
    
    lazy var loadingViewController = LoadingViewController()
    
    // MARK: IBOutlets
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var orderContainerView: UIView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var orderButton: UIButton!
    
    // Mark: IBAction
    
    @IBAction func orderButtonWasPressed(_ sender: UIButton) {
        createOrder()
    }
    
    // MARK: View

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        registerNib()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupContent()
    }
}

// MARK: Setup

private extension CartViewController {
    
    func setup() {
        title = "Cart"
        orderContainerView.layer.setFoodlyCustomShadow()
        orderButton.layer.setFoodlyCustomShadow()
        orderButton.setTitle("Place order", for: .normal)
        priceLabel.text = "\(CartItem.totalPriceOfItems(in: cart)) kr"
    }
    
    func setupContent() {
        orderButton.layer.cornerRadius = orderButton.frame.height * 0.5
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 110
    }
    
    func registerNib() {
        let identifier = CartTableViewCell.reuseIdentifier()
        let cellNib = UINib(nibName: identifier, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: identifier)
    }
}

// MARK: TableView

extension CartViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Section
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return restaurant.name
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = .foodlyRegularFont(withSize: 20)
            header.textLabel?.textColor = .foodlyColor(.white)
            header.backgroundView?.backgroundColor = UIColor.clear
        }
    }
    
    // MARK: Row
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cart.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = CartTableViewCell.reuseIdentifier()
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! CartTableViewCell
        let index = cart[indexPath.row]
        cell.setQuantity(to: index.quantity)
        cell.setMenuItem(to: index.menuItem.name)
        cell.setPricePerUnit(to: index.menuItem.price)
        cell.setTotalPrice(to: index.menuItem.price * index.quantity)
        return cell
    }
    
    // MARK: Edit
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Remove") { (action, indexPath) in
            self.tableView.dataSource?.tableView?(self.tableView, commit: .delete, forRowAt: indexPath)
            return
        }
        
        deleteButton.backgroundColor = UIColor.foodlyColor(.lightGray)
        return[deleteButton]
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.updateCartProtocol.removeFromCart(cart[indexPath.row].menuItem)
            self.cart.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.priceLabel.text = "\(CartItem.totalPriceOfItems(in: cart)) kr"
        }
        
        if cart.isEmpty {
            displayAlertLabel(withMessage: "No items in cart. Return to menu and add some.")
        }
    }
}

// MARK: Helpers

private extension CartViewController {
    
    func displayAlertLabel(withMessage message: String) {
        let alertLabel = AlertLabel()
        alertLabel.textColor = UIColor.foodlyColor(.darkGray)
        alertLabel.text = message
        alertLabel.frame.size.width = tableView.frame.width - 30
        alertLabel.sizeToFit()
        alertLabel.center = view.center
        alertLabel.alpha = 0.0
        view.addSubview(alertLabel)
        
        UIView.animate(withDuration: animationDuration) {
            self.tableView.alpha = 0.0
            self.totalLabel.alpha = 0.0
            self.orderContainerView.alpha = 0.0
            self.priceLabel.alpha = 0.0
            self.orderButton.alpha = 0.0
            alertLabel.alpha = 1.0
        }
    }
    
    func createOrder() {
        add(loadingViewController)
        
        DataController.createOrder(restaurantId: restaurant.id, cart: cart) { (order, error) in
            guard let order = order, error == nil else {
                DispatchQueue.main.async {
                    self.loadingViewController.remove()
                    self.displayAlertLabel(withMessage: "Something went wrong, failed to place order.")
                }
                
                return
            }
            
            self.presentOrderOverview(for: order)
        }
    }
    
    func presentOrderOverview(for order: Order) {
        DispatchQueue.main.async {
            if let viewController = StoryboardInstance.home.instantiateViewController(withIdentifier: "OrderOverviewViewController") as? OrderOverviewViewController {
                viewController.restaurants = [self.restaurant]
                viewController.orders = [order]
                viewController.isOrderConfirmation = true
                    viewController.dismissProtocol = self.dismissProtocol
                self.loadingViewController.remove()
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
}
