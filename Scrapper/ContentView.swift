//
//  ContentView.swift
//  Scrapper
//
//  Created by Cosmin Dolha on 07.01.2023.
//

import SwiftUI
import SwiftSoup



struct ContentView: View {
    
    @ObservedObject var scrapperModel = ScrapperModel()
    @State var articleList:[String] = []
    @State var articleTitle = ""
    @State var articleContent = ""
    @State var myOpacity = 0.0
    var body: some View {
        HStack {
                VStack(alignment: .leading){
                    VStack(alignment: .leading){

                        ForEach(scrapperModel.articleList, id: \.self) { article in
                            Text(article)
                                .transition(.opacity)
                                .foregroundColor(Color.green)
                                .font(.title2)
                                .lineLimit(nil)
                        }
                    }
                }.frame(width: 600, alignment: .topLeading).padding(.leading, 30)
                Spacer()
            ScrollView(.vertical){
             VStack(alignment: .leading){
                //multiline
                
                ForEach(scrapperModel.sumarizedArticleList, id: \.self){ article in
                    //no limit on height
                    Text(article.title).font(.title).lineLimit(nil).padding(.bottom, 10)
                    Text(article.content)
                        .transition(.opacity)
                        .font(.title2)
                         .lineLimit(nil)
                         .padding(.bottom, 10)
                         HStack{
                    Text("Sentiment:")
                        .font(.title2)
                        .foregroundColor(Color.green)
                    Text(article.sentiment)
                         .font(.title2)
                         }.padding(.bottom, 40)
                        
                }
                
             }.transition(.opacity)
            }.frame(width: 800, alignment: .topLeading)
            
        }
        
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    
    
    
    
    
    
    
    func scrapCnn(completion: @escaping (Result<String, Error>) -> Void) {
        let url = "https://edition.cnn.com/"
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
                let title: Element = try doc.select("title").first()!
                let titleText: String = try title.text()
                completion(.success(titleText))
            } catch {
                completion(.failure(Error.unknownError))
            }
        }.resume()
    }
    
}
