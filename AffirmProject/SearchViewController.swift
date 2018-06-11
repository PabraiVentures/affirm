//
//  ViewController.swift
//  AffirmProject
//
//  Created by Nathan Pabrai on 6/11/18.
//  Copyright © 2018 Nathan Pabrai. All rights reserved.
//

import SnapKit
import UIKit

class SearchViewController: UIViewController {
    static let cellHeight:CGFloat = 120
    lazy var flowLayout = GridCollectionViewFlowLayout()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
    lazy var searchField = UITextField(frame: .zero)
    lazy var imageFetcher = ImageFetcher()
    lazy var searchButton = UIButton()
    
    var currentImagePage = 1
    var currentQuery = ""
    var imageUrls = [String]() {
        didSet {
            imageUrlToImages = [String: UIImage?]()
        }
    }
    var imageUrlToImages = [String: UIImage?]()
    
	override func viewDidLoad() {
		super.viewDidLoad()
        imageFetcher.delegate = self
        setupViews()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
    
    func setupViews() {
        view.addSubview(searchField)
        view.addSubview(collectionView)
        view.addSubview(searchButton)
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        collectionView.addGestureRecognizer(gestureRecognizer)
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor.white
        searchField.placeholder = "Search here"
        searchButton.setTitle("Search", for: .normal)
        searchButton.setTitleColor(UIColor.darkGray, for: .normal)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        
        searchField.snp.makeConstraints { (make) in
            make.left.equalTo(view).offset(20)
            make.right.equalTo(searchButton.snp.left).offset(-20)
            make.top.equalTo(view).offset(48)
            make.height.equalTo(30)
        }
        
        searchButton.snp.makeConstraints { (make) in
            make.left.equalTo(searchField.snp.right).offset(20)
            make.right.equalTo(view).offset(-20)
            make.top.equalTo(view).offset(48)
            make.height.equalTo(30)
            make.width.equalTo(100)
        }
        
        collectionView.snp.makeConstraints { (make) in
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.top.equalTo(searchField.snp.bottom).offset(10)
            make.bottom.equalTo(view).offset(-20)
        }

    }

    @objc func dismissKeyboard() {
        searchField.resignFirstResponder()
    }
    
    @objc func searchTapped() {
        currentQuery = searchField.text ?? ""
        guard let query = searchField.text, query != "" else { return }
        imageFetcher.searchFor(queryString:query)
        collectionView.setContentOffset(.zero, animated: true)
    }
}

extension SearchViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionViewCell.identifier, for: indexPath) as? ImageCollectionViewCell else { return ImageCollectionViewCell() }
        let url = imageUrls[indexPath.item]
        //Todo Handle error state and empty state
        if let image = imageUrlToImages[url] as? UIImage {
            cell.setLoaded(withImage: image)
            cell.imageView.frame = cell.bounds
        } else {
            cell.setLoading()
            cell.label.frame = cell.bounds
            imageFetcher.fetch(imageUrlString: url)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if imageUrls.count == (indexPath.row + 1) {
            //TODO Fix edge case where it is possible fire multiple requests for the same page
            if !currentQuery.isEmpty {
                imageFetcher.searchFor(queryString: currentQuery, page: currentImagePage + 1)
            }
        }
    }
}

extension SearchViewController: ImageFetcherDelegate {
    func searchRequestCompletedWithResponse(_ response: [String : Any], isPageUpdate: Bool) {
        var newImageUrls = [String]()
        if let photos = response["photos"] as? [String:Any] {
            if let innerPhotos = photos["photo"] as? [[String:Any]] {
                print("\(innerPhotos)")
                innerPhotos.forEach { photo in
                    if let url = photo["url_s"] as? String {
                        if isPageUpdate {
                            imageUrls.append(url)
                        } else {
                            newImageUrls.append(url)
                        }
                    }
                }
                if !isPageUpdate {
                    imageUrls = newImageUrls
                }
                if isPageUpdate {
                    currentImagePage += 1
                }
                collectionView.reloadData()
            }
        }
        //Todo handle parsing errors
    }
    
    func searchRequestFailedWithError(_ error: ImageFetcher.ImageFetcherError) {
        //Show Error
    }
    
    func imageRequestCompletedWithResponse(_ response: UIImage, forImageUrlString imageUrlString: String) {
        imageUrlToImages[imageUrlString] = response
        
        for (index, element) in imageUrls.enumerated() {
            if element == imageUrlString {
               collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }
        }
    }
    
    func imageRequestFailedWithError(_ error: ImageFetcher.ImageFetcherError, forImageUrlString imageUrlString: String) {
        return
    }
}

