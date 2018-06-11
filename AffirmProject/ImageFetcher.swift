//
//  ImageFetcher.swift
//  AffirmProject
//
//  Created by Nathan Pabrai on 6/11/18.
//  Copyright © 2018 Nathan Pabrai. All rights reserved.
//

import UIKit

/**
Delegate methods will always be called on the main queue
*/
protocol  ImageFetcherDelegate: class {
	/**
	Called on main queue when there is a successful response for the image search request
	*/
    func searchRequestCompletedWithResponse(_ response:[String:Any], isPageUpdate: Bool)
	
	/**
	Called on main queue when there is an error with the image search request
	*/
	func searchRequestFailedWithError(_ error:ImageFetcher.ImageFetcherError)
    
    /**
     Called on main queue when there is a successful response for the image request
     */
    func imageRequestCompletedWithResponse(_ response:UIImage, forImageUrlString imageUrlString:String)
    
    /**
     Called on main queue when there is an error with the image request
     */
    func imageRequestFailedWithError(_ error:ImageFetcher.ImageFetcherError, forImageUrlString imageUrlString:String)
}

class ImageFetcher: NSObject {
    static let timeout:TimeInterval = 4.0
    
	enum ImageFetcherError: Error {
		case invalidQuery
		case serverError
		case parsingError
	}
	weak var delegate: ImageFetcherDelegate? = nil
	
	/**
	Takes queryString and page and fetches the search results asynchronously. It calls the delegate methods on the main queue.
	
	- parameter queryString: the string to search images for
	- parameter page: the page of results to request. Default = 1 (the first page)
	*/
	func searchFor(queryString: String, page: Int = 1) {
        let isPageUpdate = page != 1
		DispatchQueue.global(qos: .userInteractive).async { [weak self] in
			guard let request = self?.requestForQuery(queryString, page: page) else {
				self?.delegate?.searchRequestFailedWithError(.invalidQuery)
				return
			}
			URLSession.shared.dataTask(with: request, completionHandler: { (data, urlResponse, error) in
                self?.handleSearchRequestCompletionWith(data: data, response: urlResponse, error: error, isPageUpdate: isPageUpdate)
			}).resume()
			
		}
	}
    
    /**
     Takes an imageUrlString to fetch asynchronously and return a UIImage on the main queue via delegate methods.
     - parameter imageUrlString: A string with the url of the image to fetch
     */
    
    func fetch(imageUrlString:String) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let request = self?.requestForImageUrlString(imageUrlString) else {
                self?.delegate?.imageRequestFailedWithError(.invalidQuery, forImageUrlString: imageUrlString)
                return
            }
            URLSession.shared.dataTask(with: request, completionHandler: { (data, urlResponse, error) in
                self?.handleImageRequestCompletionWith(data: data, response: urlResponse, error: error, imageUrlString: imageUrlString)
            }).resume()
        }
    }
    
	private func requestForQuery(_ query:String, page: Int) -> URLRequest? {
		if page < 1 { return nil }
		let rawUrl = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=675894853ae8ec6c242fa4c077bcf4a0&text=\(query)&extras=url_s&format=json&nojsoncallback=1&page=\(page)"
		guard let url = URL(string: rawUrl) else { return nil }
        return URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: ImageFetcher.timeout)
	}
    
    private func handleSearchRequestCompletionWith(data:Data?, response:URLResponse?, error:Error?, isPageUpdate:Bool) {
		guard let response = response as? HTTPURLResponse, let data = data else {
			delegate?.searchRequestFailedWithError(.serverError)
			return
		}
		if error != nil, response.statusCode != 200{
			delegate?.searchRequestFailedWithError(.serverError)
		}
		guard let responseDict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String:Any] else {
			delegate?.searchRequestFailedWithError(.parsingError)
			return
		}

		DispatchQueue.main.async { [weak self] in
            self?.delegate?.searchRequestCompletedWithResponse(responseDict, isPageUpdate: isPageUpdate)
		}
	}

    private func requestForImageUrlString(_ imageUrlString:String) -> URLRequest? {
        guard let url = URL(string: imageUrlString) else { return nil }
        return URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: ImageFetcher.timeout)
    }
    
    private func handleImageRequestCompletionWith(data:Data?, response:URLResponse?, error:Error?, imageUrlString: String) {
        guard let response = response as? HTTPURLResponse, let data = data else {
            delegate?.searchRequestFailedWithError(.serverError)
            return
        }
        if error != nil, response.statusCode != 200{
            delegate?.searchRequestFailedWithError(.serverError)
        }
        guard let mimeType = response.mimeType, mimeType.hasPrefix("image"),
            let image = UIImage(data: data) else {
                delegate?.searchRequestFailedWithError(.parsingError)
                return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.imageRequestCompletedWithResponse(image, forImageUrlString: imageUrlString)
        }
    }
}
