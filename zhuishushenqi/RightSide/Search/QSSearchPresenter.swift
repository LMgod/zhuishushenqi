//
//  QSSearchPresenter.swift
//  zhuishushenqi
//
//  Created Nory Cao on 2017/4/10.
//  Copyright © 2017年 QS. All rights reserved.
//
//  Template generated by Juanpe Catalán @JuanpeCMiOS
//

import UIKit

class ZSSearchViewModel {
    
    var keywords = ""
    
    fileprivate var hotwords:[String] = []
    
    fileprivate var webService:ZSSearchWebService = ZSSearchWebService()
    // 换一批热词的基准
    fileprivate var newIndex = 0
    fileprivate let SearchStoreKey = "SearchHistory"
    
    //MARK: - 换一批热门词
    func newHotwords(callback:ZSSearchWebCallback?) {
        if hotwords.count == 0 {
            fetchHotwords(callback: callback)
        } else {
            subHotwords(callback: callback)
        }
    }
    
    func fetchAutoComplete(key:String,callback:ZSSearchWebCallback?){
        webService.fetchAutoComplete(key: key) { (list) in
            callback?(list)
        }
    }
    
    func fetchBooks(key:String, start:Int, limit:Int, callback:ZSSearchWebAnyCallback<[Book]>?){
        webService.fetchBooks(key: key, start: start, limit: limit) { (books) in
            callback?(books)
        }
    }
    
    fileprivate func subHotwords(callback:ZSSearchWebCallback?){
        if hotwords.count > 0 {
            var subWords:[String] = []
            for item in newIndex..<newIndex+6 {
                subWords.append(hotwords[item%hotwords.count])
            }
            newIndex = newIndex + 6
            callback?(subWords)
        } else {
            callback?([])
        }
    }
    
    fileprivate func fetchHotwords(callback:ZSSearchWebCallback?) {
        webService.fetchHotwords({ (words) in
            self.newIndex = 0
            self.hotwords = words ?? []
            self.subHotwords(callback: callback)
        })
    }
    
    //MARK: - local data
    @discardableResult
    func fetchHistoryList(_ callback:ZSSearchWebCallback?)-> [String]?{
        let store = getHistoryStore()
        let historyList = store?.getObjectById(SearchStoreKey, fromTable: searchHistory) as? [String]
        callback?(historyList)
        return historyList
    }
    
    func clearSearchList(){
        let store = getHistoryStore()
        store?.clearTable(searchHistory)
    }
    
    func addToHistory(history:String){
        if history == ""{
            return
        }
        if !searchWordExist(key: history) {
            let store = getHistoryStore()
            var list = fetchHistoryList(nil) ?? []
            list.append(history.trimmingCharacters(in: CharacterSet(charactersIn: " ")))
            store?.clearTable(searchHistory)
            store?.put(list, withId: SearchStoreKey, intoTable: searchHistory)
            
        }
    }
    
    fileprivate func searchWordExist(key:String)->Bool{
        var isExist = false
        let list = fetchHistoryList(nil)
        if let historyList = list {
            for item in historyList {
                if item == key {
                    isExist = true
                    break;
                }
            }
        }
        return isExist
    }
    
    fileprivate func getHistoryStore()->YTKKeyValueStore?{
        let store  = YTKKeyValueStore(dbWithName: dbName)
        if store?.isTableExists(searchHistory) == false {
            store?.createTable(withName: searchHistory)
        }
        return store
    }

}

class QSSearchPresenter: QSSearchPresenterProtocol {

    weak var view: QSSearchViewProtocol?
    var interactor: QSSearchInteractorProtocol
    var router: QSSearchWireframeProtocol
    
    var hotwords:[String] = [] {
        didSet{
            
        }
    }
    var history:[String] = [] {
        didSet{
            
        }
    }
    var keywords:[String] = []
    
    var books:[Book] = []

    init(interface: QSSearchViewProtocol, interactor: QSSearchInteractorProtocol, router: QSSearchWireframeProtocol) {
        self.view = interface
        self.interactor = interactor
        self.router = router
    }
    
    func viewDidLoad(){
        self.interactor.fetchHotwords()
        self.interactor.fetchSearchList()
    }
    
    func didClickClearBtn(){
        interactor.clearSearchList()
    }
    
    func didSelectHotWord(hotword:String){
        view?.showActivityView()
        interactor.updateHistoryList(history: hotword)
        interactor.fetchBooks(key: hotword)
    }
    
    func didClickChangeBtn(){
        fetchHotwordsSuccess(hotwords: interactor.subWords())
    }
    
    func didSelectResultRow(indexPath:IndexPath){
        router.presentDetails(books[indexPath.row])
    }
    
    func didSelectHistoryRow(indexPath:IndexPath){
        view?.showActivityView()
        view?.showBooks(books: [], key: history[indexPath.row])
        interactor.fetchBooks(key: history[indexPath.row])
    }
    
    func didSelectAutoCompleteRow(indexPath: IndexPath) {
        view?.showActivityView()
        view?.showBooks(books: [], key: keywords[indexPath.row])
        interactor.updateHistoryList(history: keywords[indexPath.row])
        interactor.fetchBooks(key: keywords[indexPath.row])
    }
    
    func fetchBooks(key:String){
        view?.showActivityView()
        interactor.fetchBooks(key: key)
    }
}

extension QSSearchPresenter:QSSearchInteractorOutputProtocol{

    func fetchHotwordsSuccess(hotwords:[String]){
        self.hotwords = hotwords
        view?.showHotwordsData(hotwords: hotwords)
    }
    
    func fetchHotwordsFailed(){
        
    }
    
    func fetchAutoComplete(keys: [String]) {
        self.keywords = keys
        view?.hideActivityView()
        view?.showAutoComplete(keywords: keys)
    }
    
    func searchListFetch(list:[[String]]){
        self.history = list[1]
        view?.showSearchListData(searchList: list)
    }
    
    func fetchBooksSuccess(books:[Book],key:String){
        self.books = books
        view?.hideActivityView()
        view?.showBooks(books: self.books,key:key)
    }
    
    func fetchBooksFailed(key:String) {
        self.books = []
        view?.hideActivityView()
        view?.showBooks(books: self.books,key:key)
    }

    func showResult(key: String) {
        self.books = []
        view?.showBooks(books: self.books, key: key)
    }
}
