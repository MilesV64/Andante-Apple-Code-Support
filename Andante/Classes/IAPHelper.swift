//
//  IAPHelper.swift
//  Andante
//
//  Created by Miles Vinson on 10/15/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import StoreKit

class IAPHelper: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    public static let shared = IAPHelper()
    
    private static let PRODUCT_ID = "com.andante.pro"
    
    private var product: SKProduct?
    private var request: SKProductsRequest?
    
    public var successAction: (()->Void)?
    public var failAction: (()->Void)?
    private var restoreAction: ((_:Bool)->Void)?
    
    private var didRestoreProduct = false
    
    private func log(_ string: String) {
        print("IAPHelper: \(string)")
    }
    
    public var localizedPrice: String {
        if let product = self.product {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceLocale
            return formatter.string(from: product.price) ?? ""
        }
        return ""
    }
    
    public func startObserving() {
        log("Begin observing")
        SKPaymentQueue.default().add(self)
    }
    
    public func stopObserving() {
        log("End observing")
        SKPaymentQueue.default().remove(self)
    }
    
    public func fetchProducts() {
        log("Fetch products")
        self.request = SKProductsRequest(productIdentifiers: [IAPHelper.PRODUCT_ID])
        request?.delegate = self
        request?.start()
    }
    
    public func requestPurchase() {
        log("Request purchase")
        if SKPaymentQueue.canMakePayments() {
            log("Can make payments")
            if self.product == nil {
                fetchProducts()
            }
            if let product = self.product {
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)
                log("Start purchase")
            }
        }
    }
    
    public func restorePurchase(loadingBlock: (()->Void)?, completion: @escaping ((_ success:Bool)->Void)) {
        log("Restore Purchase")
        didRestoreProduct = false
        
        self.restoreAction = completion
        loadingBlock?()
        
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        log("Receive fetch response")
        if let product = response.products.first {
            log("Fetch success")
            self.product = product
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("fdsafadsfasdfas")
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                log("Purchasing")
                break
            case .purchased:
                handleSuccess(transaction)
            case .restored:
                handleRestore(transaction)
            case .failed, .deferred:
                handleFailure(transaction)
            @unknown default:
                log("Default")
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        log("Restore complete. didRestoreProduct = \(didRestoreProduct)")
        restoreAction?(didRestoreProduct)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        log(error.localizedDescription)
        self.restoreAction?(false)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(error)
    }
    
    func handleSuccess(_ transaction: SKPaymentTransaction) {
        log("Payment success")
        
        Settings.isPremium = true

        self.successAction?()
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func handleRestore(_ transaction: SKPaymentTransaction) {
        log("Payment restored")
        
        didRestoreProduct = true
        Settings.isPremium = true
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func handleFailure(_ transaction: SKPaymentTransaction) {
        log("Payment failed: \(String(describing: transaction.error?.localizedDescription))")
        self.failAction?()
    }
    
}
