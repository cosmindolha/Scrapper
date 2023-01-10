//
//  ScrapperModel.swift
//  Scrapper
//
//  Created by Cosmin Dolha on 08.01.2023.
//

import Foundation
import SwiftSoup
import SwiftUI

struct ArticleToRead {
    var title: String
    var content: String
}
struct SummarizedArticle:Hashable {
    var id: UUID = UUID()
    var sentiment:String = "Not analyzed"
    var title: String
    var content: String
}


enum Error: Swift.Error {
    case invalidResponse
    case invalidData
    case unknownError
}



class  ScrapperModel: ObservableObject {
    
    @Published var articleList:[String] = []
    @Published var status: String = ""
    
    var articlesInMem:[String] = []
    var articlesInMemRaw:[String] = []
    var articleLinksInMem:[String] = []

    var articleToReadList:[ArticleToRead] = []

    @Published var sumarizedArticleList:[SummarizedArticle] = []

    var articlesSentimentAnalized = 0
    
    init() {
        onStart()
    }
    
    
    //function that adds recursevly the articles to the list, using a delay

    func addToListWithDelay(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.articlesInMem.count > 0 {
                withAnimation (.easeInOut(duration: 0.2)) {
                    self.articleList.append(self.articlesInMem[0])
                }
                self.articlesInMem.remove(at: 0)
                self.addToListWithDelay()
            }else{
                self.articleList.append("latest news links added...")
                self.articleList.append("getting the articles...")
                self.getArticles()
            }
        }
    }
    
    //read article recusrive function
    func getArticles(){

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

            if self.articleLinksInMem.count > 0 {
                self.scrapArticle(from: self.articleLinksInMem[0]) { result in
                    switch result {
                    case .success(let article):
                        DispatchQueue.main.async {
                            withAnimation (.easeInOut(duration: 0.2)) {
                                self.articleList.append(article.0)
                                
                            }
                            self.articleToReadList.append(ArticleToRead(title: article.0, content: article.1))
                            
                            self.articleLinksInMem.remove(at: 0)
                            self.getArticles()
                        }
                    case .failure(let error):
                        print("An error occurred: \(error)")
                    }
                }

            }else{
                self.articleList.append("articles added...")
                self.articleSumarisation()
            }
        }

    }

    //begin article sumarisation using GPT-3

    func articleSumarisation(){
        self.articleList.append("start article sumarisation usimg GPT-3...")
        sumarizeArticleOneAtATime()
    }

    //using recursion summarize articles from articleToReadList, using GPT-3



    func sumarizeArticleOneAtATime(){
            if self.articleToReadList.count > 0 {
                summarizeGPT3(article: self.articleToReadList[0].content) { result in
                        DispatchQueue.main.async {
                            withAnimation (.easeInOut(duration: 0.3)) {
                                var cleannerTitle = self.removeStringEndingIn(fromString: self.articleToReadList[0].title, delimitator: "|")

                                cleannerTitle = cleannerTitle.replacingOccurrences(of: "|", with: "")

                                let sumarizedArticle = SummarizedArticle(title: cleannerTitle, content: result ?? "empty response")
                                self.sumarizedArticleList.append(sumarizedArticle)

                            }
                            self.articleToReadList.remove(at: 0)
                            self.sumarizeArticleOneAtATime()
                        }
                }
            }else{
                self.articlesSentimentAnalized = self.sumarizedArticleList.count
                self.articleList.append("articles summarized...")
                self.sentimentAnalysis()
            }
        
    }

    

    //begin sentiment analysis

    func detectSentimentOneArticleAtTime(){
        if self.articlesSentimentAnalized > 0 {
            let articleIndex = self.articlesSentimentAnalized - 1
            getSentiment(article: self.sumarizedArticleList[articleIndex].content) { result in
                    DispatchQueue.main.async {
                        withAnimation (.easeInOut(duration: 0.3)) {
                            self.sumarizedArticleList[articleIndex].sentiment = result ?? "empty response"
                        }
                       self.articlesSentimentAnalized -= 1
                        self.detectSentimentOneArticleAtTime()
                    }
            }
        }else{
            self.articleList.append("sentiment analysis done...")
        }
    }

    func sentimentAnalysis(){
        self.articleList.append("start sentiment analysis using GPT-3...")
        detectSentimentOneArticleAtTime()
    }

    func buildArticlesLinksList(){
        for link in self.articlesInMemRaw {
            let link = "https://edition.cnn.com" + link
            self.articleLinksInMem.append(link)
        }
    }
    
    
    
    



    
    func onStart(){
        DispatchQueue.main.async {
            self.articleList.append("getting latest news links...")
            self.scrapArticlesCnn { result in
                switch result {
                case .success(let articles):
                    
                    DispatchQueue.main.async {
                      
                            
                        self.articlesInMem = articles
                        self.articlesInMemRaw = articles
                            
                        self.buildArticlesLinksList()
                        self.addToListWithDelay()
                       
                    }
                   
                case .failure(let error):
                    print("An error occurred: \(error)")
                }
            }
        }
    }

    func scrapArticlesCnn(completion: @escaping (Result<[String], Error>) -> Void) {
        let url = "https://edition.cnn.com/markets"
        let request = URLRequest(url: URL(string: url)!)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(Error.unknownError))
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(Error.invalidData))
                return
            }

            do {
                let doc: Document = try SwiftSoup.parse(html)
                let links: [Element] = try doc.select("a").array()
             
                let linkHrefs: [String] = try links.map { try $0.attr("href") }
                
                let filteredLinks = self.filterLinksByString(links: linkHrefs, string: "2023")
               // print(filteredLinks)

                completion(.success(filteredLinks))
            } catch {
                completion(.failure(Error.unknownError))
            }
        }.resume()
    
    }

    func filterLinksByString(links: [String], string: String) -> [String] {
        var filteredLinks: [String] = []
        for link in links {
            if link.contains(string) {
                filteredLinks.append(link)
            }
        }
        return filteredLinks
    }
    


    func scrapArticle(from url: String, completion: @escaping (Result<(String, String), Error>) -> Void) {
        let request = URLRequest(url: URL(string: url)!)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(Error.unknownError))
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(Error.invalidData))
                return
            }

            do {
                let doc: Document = try SwiftSoup.parse(html)
                
                var titleText: String = ""

                if let title: Element = try doc.select("title").first(){
                    
                    titleText = try title.text()
                    
                }
                else { self.status = "title swiftsoup selector not found" }
                
                    
               
                    
                    
                let article: Element = try doc.select(".article__content-container").first()!
                let articleText: String = try article.text()


                completion(.success((titleText, articleText)))

            } catch {
                completion(.failure(Error.unknownError))
            }
        }.resume()
    }

    // //function that removes string before the string "--"
    // func stripArticle(article: String) -> String {
    //     let strippedArticle = article.components(separatedBy: "CNN")
    //     return strippedArticle[1]
    // }
        
    func removeStringEndingIn(fromString: String, delimitator: String) -> String {
        let strippedString = fromString.components(separatedBy: "CNN")
        return strippedString[0]
    }
  
}


    


