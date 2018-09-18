//
//  Zap
//
//  Created by Otto Suess on 28.01.18.
//  Copyright © 2018 Otto Suess. All rights reserved.
//

import Bond
import Foundation
import Lightning
import ReactiveKit
import SwiftLnd

enum HeaderTableCellType: Equatable {
    case header(String)
    case transactionEvent(TransactionEvent)
    case channelEvent(DateWrappedChannelEvent)
    case createInvoiceEvent(CreateInvoiceEvent)
    case failedPayemntEvent(FailedPaymentEvent)
}

final class HistoryViewModel: NSObject {
    private let transactionService: TransactionService
    private let nodeStore: LightningNodeStore
    
    let isLoading = Observable(true)
    let dataSource: MutableObservableArray<HeaderTableCellType>
    let isEmpty: Signal<Bool, NoError>
    
    let searchString = Observable<String?>(nil)
    let filterSettings = Observable<FilterSettings>(FilterSettings.load())
    let isFilterActive: Signal<Bool, NoError>
        
    init(transactionService: TransactionService, nodeStore: LightningNodeStore) {
        self.transactionService = transactionService
        self.nodeStore = nodeStore
        dataSource = MutableObservableArray()

        isEmpty =
            combineLatest(dataSource, isLoading) { sections, isLoading in
                sections.dataSource.isEmpty && !isLoading
            }
            .distinct()
            .debounce(interval: 0.5)
            .start(with: false)

        isFilterActive = filterSettings
            .map { $0 != FilterSettings() }

        super.init()

//        transactionService.transactions
//            .observeNext { [weak self] in
//                self?.updateTransactionViewModels(transactions: $0)
//            }
//            .dispose(in: reactive.bag)

//        combineLatest(searchString, filterSettings)
//            .observeNext { [weak self] in
//                self?.filterTransactionViewModels(searchString: $0, filterSettings: $1)
//            }
//            .dispose(in: reactive.bag)
        
        /////// new stuff
        
        do {
            let payments = try TransactionEvent.payments()
            
            let createInvoiceEvents = try CreateInvoiceEvent.events()
            
            let dateEstimator = DateEstimator()
            let channelEvents = try ChannelEvent.events().map { (channelEvent: ChannelEvent) -> DateWrappedChannelEvent in
                dateEstimator.wrapChannelEvent(channelEvent)
            }
            
            let failedPaymentEvents = try FailedPaymentEvent.events()
            
            var cellTypes = [DateProvidingEvent]()
            cellTypes.append(contentsOf: payments)
            cellTypes.append(contentsOf: channelEvents)
            cellTypes.append(contentsOf: createInvoiceEvents)
            cellTypes.append(contentsOf: failedPaymentEvents)
            
            let sectionedCellTypes = bondSections(cellTypes)
            
            dataSource.replace(with: sectionedCellTypes)
        } catch {
            print(error)
        }
    }
    
//    func refresh() {
//        transactionService.update()
//    }
//
//    func setTransactionHidden(_ transaction: Transaction, hidden: Bool) {
//        let newAnnotation = transactionService.setTransactionHidden(transaction, hidden: hidden)
//        updateAnnotation(newAnnotation, for: transaction)
//
//        if !filterSettings.value.displayArchivedTransactions {
//            filterTransactionViewModels(searchString: searchString.value, filterSettings: filterSettings.value)
//        }
//    }
//
//    func updateAnnotationType(_ type: TransactionAnnotationType, for transaction: Transaction) {
//        let annotation = transactionService.annotation(for: transaction)
//        let newAnnotation = annotation.settingType(to: type)
//        updateAnnotation(newAnnotation, for: transaction)
//    }
//
//    func updateAnnotation(_ annotation: TransactionAnnotation, for transaction: Transaction) {
//        transactionService.updateAnnotation(annotation, for: transaction)
//        for transactionViewModel in transactionViewModels where transactionViewModel.id == transaction.id {
//            transactionViewModel.annotation.value = annotation
//            break
//        }
//    }
//
//    func updateFilterSettings(_ newFilterSettings: FilterSettings) {
//        filterSettings.value = newFilterSettings
//        newFilterSettings.save()
//    }
    
    // MARK: - Private
    
//    private func updateTransactionViewModels(transactions: [Transaction]) {
//        let newTransactionViewModels = transactions
//            .compactMap { transaction -> TransactionViewModel in
//                let annotation = transactionService.annotation(for: transaction)
//
//                if let oldTransactionViewModel = self.transactionViewModels.first(where: { $0.transaction.isTransactionEqual(to: transaction) }) {
//                    return oldTransactionViewModel
//                } else {
//                    return TransactionViewModel.instance(for: transaction, annotation: annotation, nodeStore: nodeStore)
//                }
//            }
//
//        transactionViewModels = newTransactionViewModels
//        filterTransactionViewModels(searchString: searchString.value, filterSettings: filterSettings.value)
//    }
//
//    private func filterTransactionViewModels(searchString: String?, filterSettings: FilterSettings) {
//        let filteredTransactionViewModels = transactionViewModels
//            .filter { $0.matchesFilterSettings(filterSettings) }
//            .filter { $0.matchesSearchString(searchString) }
//
//        let result = bondSections(transactionViewModels: filteredTransactionViewModels)
//
//        DispatchQueue.main.async {
//            self.dataSource.replace(with: result, performDiff: true)
//            self.isLoading.value = false
//        }
//    }
//
    private func sortedSections(transactionViewModels: [DateProvidingEvent]) -> [(Date, [DateProvidingEvent])] {
        let grouped = transactionViewModels
            .grouped { transaction -> Date in
                transaction.date.withoutTime
            }
    
        return Array(zip(grouped.keys, grouped.values))
            .sorted { $0.0 > $1.0 }
    }

    private func bondSections(_ transactionViewModels: [DateProvidingEvent]) -> [HeaderTableCellType] {
        let sortedSections = self.sortedSections(transactionViewModels: transactionViewModels)

        return sortedSections.flatMap { input -> [HeaderTableCellType] in
            let sortedItems = input.1.sorted { $0.date > $1.date }
            guard let date = input.1.first?.date else { return [] }
            let dateString = date.localized
            return [HeaderTableCellType.header(dateString)] + sortedItems.compactMap {
                if let channelEvent = $0 as? DateWrappedChannelEvent {
                    return HeaderTableCellType.channelEvent(channelEvent)
                } else if let transactionEvent = $0 as? TransactionEvent {
                    return HeaderTableCellType.transactionEvent(transactionEvent)
                } else if let createInvoiceEvent = $0 as? CreateInvoiceEvent {
                    return HeaderTableCellType.createInvoiceEvent(createInvoiceEvent)
                } else if let failedPaymentEvent = $0 as? FailedPaymentEvent {
                    return HeaderTableCellType.failedPayemntEvent(failedPaymentEvent)
                } else {
                    fatalError("missing cell implementation")
                }
            }
        }
    }
}