//
//  ModuleBuilder.swift
//  Exchange MVP
//
//  Created by Oleg Shum on 09.02.2022.
//
import UIKit

protocol Builder {
    func createMainModule() -> MainViewController
}

final class ModuleBuilder {
    
    private let networkService: Networkable
    
    init() {
        networkService = NetworkService()
    }
}

extension ModuleBuilder: Builder {
    
    func createMainModule() -> MainViewController {
        let view = MainViewController()
        let presenter = MainPresenter(networkService: networkService)
        view.presenter = presenter
        presenter.view = view
        return view
    }
}
