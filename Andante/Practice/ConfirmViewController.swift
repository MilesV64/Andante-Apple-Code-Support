//
//  ConfirmViewController.swift
//  Andante
//
//  Created by Miles Vinson on 11/17/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class ConfirmViewController: UIViewController {
    
    var confirmView: ConfirmView
    var presenter: PracticeViewController
    
    public var saveAction: (()->Void)?
    public var didCloseAction: (()->Void)?
    
    private var didSave = false
        
    let dimView = UIView()
    
    init(_ presenter: PracticeViewController, session: SessionModel) {
        self.presenter = presenter
        self.confirmView = ConfirmView(session)
        
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confirmView.saveAction = {
            [weak self] in
            guard let self = self else { return }
            self.didSave = true
            self.saveAction?()
        }
        
        confirmView.cancelHandler = {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        
        confirmView.premiumHandler = {
            [weak self] in
            guard let self = self else { return }
            self.presentModal(AndanteProViewController(), animated: true, completion: nil)
        }
        
        confirmView.setBackButtonType(.cancel)
        
        dimView.backgroundColor = PracticeColors.background
        dimView.alpha = 0
        
        presenter.view.addSubview(dimView)
        
        self.view.addSubview(confirmView)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.presenter.practiceView.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
            self.dimView.alpha = 1
        }, completion: { (context) in })
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if didSave { return }
        
        self.transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.presenter.practiceView.transform = .identity
            self.dimView.alpha = 0
        }, completion: { (context) in })
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.dimView.removeFromSuperview()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        confirmView.frame = view.bounds
        dimView.frame = presenter.view.bounds
        
    }
    
}
