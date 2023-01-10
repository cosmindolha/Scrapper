//
//  OpenAI.swift
//  GPT-3 Programmer
//
//  Created by Cosmin Dolha on 08.12.2022.
//

import Foundation
import SwiftUI

struct OpenAIResponse: Decodable {
    var id: String?
    var object: String?
    var created: Int?
    var model: String?
    var choices: [OpenAIChoice]?
    var usage: OpenAiUsage?
    struct OpenAiUsage: Decodable {
        var prompt_tokens: Int?
        var completion_tokens: Int?
        var total_tokens: Int?
    }
    struct OpenAIChoice: Decodable {
        var text: String?
        var index: Int?
        var logprobs: String?
        var finishReason: String?
    }
}



func sendPromtToOpenAI(parameters: [String: Any], completion: @escaping (OpenAIResponse?) -> Void) {
    // print(parameters)
    let openAIKey = "-------- Enter Your OpenAI API Key Here -----------"
    
    let session = URLSession.shared
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    let urlString = UserDefaults.standard.string(forKey: "openAiApiUrl") ?? "https://api.openai.com/v1/completions"
    
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }
    
    let sendData:Data = try! JSONSerialization.data(withJSONObject: parameters)
    
    var request = URLRequest(url: url)
    
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"
    request.httpBody = sendData
    
    session.dataTask(with: request) { (data, response, error) in
        if let httpResponse = response as? HTTPURLResponse {
            if(httpResponse.statusCode != 200){
                print("Server not responding")
            }
        }
        if let data = data {
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                // print(openAIResponse)
                DispatchQueue.main.async {
                    completion(openAIResponse)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }.resume()
    
}



func constructGPT3ParamSentiment(_ article:String) -> [String: Any]{
    var promt = article
    promt.append("\n\nSentiment:")
    var instructions = "Classify the sentiment in the following news article summary:\n"
    instructions.append(promt)

    let parameters: [String: Any] = [
        "model": "text-davinci-003",
        "prompt": instructions,
        "max_tokens": 100,
        "temperature": 0,
        "top_p": 1.0,
        "frequency_penalty": 0.0,
        "presence_penalty": 0.0,
    ]
    return parameters
}

func constructGPT3ParamSummarize(_ article:String) -> [String: Any]{
    var instructions = "Summarize the following news article, in maximum four sentences in a style that is easy to undestand\n article:\n"
    instructions.append(article)
   // var promt = article
  //  promt.append("\n\nTl;dr")
    let parameters: [String: Any] = [
        "model": "text-davinci-003",
        "prompt": instructions,
        "max_tokens": 200,
        "temperature": 0,
        "top_p": 1.0,
        "frequency_penalty": 0.0,
        "presence_penalty": 1,
    ]
    return parameters
}

func getSentiment(article: String, completion: @escaping (String?) -> Void) {
    
    let parameters = constructGPT3ParamSentiment(article)
    
    sendPromtToOpenAI(parameters: parameters) { response in
        
        if let response = response {
            if let choices = response.choices {
                if let choice = choices.first {
                    if let text = choice.text {
                        completion(text)
                    }
                }
            }
        }
        
    }
    
}

func summarizeGPT3(article: String, completion: @escaping (String?) -> Void) {
    
    let parameters = constructGPT3ParamSummarize(article)
    
    sendPromtToOpenAI(parameters: parameters) { response in
        
        if let response = response {
            if let choices = response.choices {
                if let choice = choices.first {
                    if let text = choice.text {
                        completion(text)
                    }
                }
            }
        }
        
    }
    
}




