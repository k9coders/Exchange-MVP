//
//  ViewController.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 09.02.2022.
//

import UIKit

protocol ViewProtocol: AnyObject {
    func updateView(_ viewModel: ViewModel, _ topRate: String)
    func updateSecondCollectionView(_ viewModel: ViewModel)
    func showAlert(result: String)
}

final class MainViewController: UIViewController {
    
    // объекты верхнего и нижнего СollectionView
    private lazy var firstCollectionView: CustomCollectionView = {
        let colletionView = CustomCollectionView()
        colletionView.delegate = self
        colletionView.dataSource = self
        return colletionView
    }()
    
    private lazy var secondCollectionView: CustomCollectionView = {
        let collectionView = CustomCollectionView()
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    //модель данных для collectionView
    private var viewModel: ViewModel?
    
    private var topIndex = 0 // индекс верхней ячейки
    private var bottomIndex = 0
    private var topValue: Double? //значение верхнего textField
    
    var presenter: PresenterProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewController()
    }
    
    @objc func didTapBarButton() {
        print(#function)
        presenter?.exchangeCurrency(topValue: topValue,
                                    topIndex: topIndex,
                                    bottomIndex: bottomIndex)
    }
}

// MARK: - ViewProtocol Impl
extension MainViewController: ViewProtocol {
    func showAlert(result: String) {
        let alert = UIAlertController(title: "Notification",
                                      message: result,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: .default))
        present(alert, animated: true)
        
        presenter?.fetchRates(topIndex: topIndex, bottomIndex: bottomIndex)
    }
    
    func updateView(_ viewModel: ViewModel,_ topRate: String) {
        self.viewModel = viewModel
        self.topValue = nil
        title = topRate
        firstCollectionView.reloadData()
        secondCollectionView.reloadData()
        print(#function)
    }
    
    func updateSecondCollectionView(_ viewModel: ViewModel) {
        self.viewModel = viewModel
        secondCollectionView.reloadData()
    }
}

//MARK: - UICollectionViewDataSource
extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == firstCollectionView {
            return viewModel?.first.count ?? 0
        }
        else {
            return viewModel?.second.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCell.reuseId, for: indexPath) as? CustomCell else {
            fatalError("CustomCell not found")
        }
        
        let model: CellModel
        guard let viewModel = self.viewModel else {
            return cell
        }
        if collectionView == firstCollectionView {
            model = viewModel.first[indexPath.item]
        } else {
            model = viewModel.second[indexPath.item]
        }
        cell.setupCell(with: model)
        cell.delegate = self
        
        return cell
    }
}


//MARK: - UICollectionViewDelegate
extension MainViewController: UICollectionViewDelegate {
    
}

// MARK: - CustomCellDelegate Impl
extension MainViewController: CustomCellDelegate {
    func didEditText(_ value: Double, _ isTop: Bool) {
        topValue = value
        print(isTop)
        if isTop == true {
            presenter?.fetchRatesAndValues(topIndex: topIndex,
                                           bottomIndex: bottomIndex,
                                           topValue: topValue ?? 0)
        } else {
            print(isTop)
        }
        
    }
}

// MARK: - UIScrollViewDelegate Impl
extension MainViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == firstCollectionView {
            guard let cell = firstCollectionView.visibleCells.first,
                  let indexPath = firstCollectionView.indexPath(for: cell) else {
                      return
                  }
            topIndex = indexPath.item
        } else if scrollView == secondCollectionView {
            guard let cell = secondCollectionView.visibleCells.first,
                  let indexPath = secondCollectionView.indexPath(for: cell) else {
                      return
                  }
            bottomIndex = indexPath.item
        }
        presenter?.fetchRates(topIndex: topIndex, bottomIndex: bottomIndex)
    }
}

// MARK: - Private methods
private extension MainViewController {
    
    func setupViewController() {
        view.backgroundColor = .systemBackground
        setupBarButton()
        setupCollectionViews()
        presenter?.loadData()
    }
    
    func setupBarButton() {
        let button = UIBarButtonItem(title: "Exchange",
                                     style: .plain,
                                     target: self,
                                     action: #selector(didTapBarButton))
        navigationItem.setRightBarButton(button, animated: true)
    }
    
    func setupCollectionViews() {
        view.addSubview(firstCollectionView)
        view.addSubview(secondCollectionView)
        
        firstCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true
        firstCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        firstCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        firstCollectionView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        secondCollectionView.topAnchor.constraint(equalTo: firstCollectionView.bottomAnchor, constant: 50).isActive = true
        secondCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        secondCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        secondCollectionView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
}
