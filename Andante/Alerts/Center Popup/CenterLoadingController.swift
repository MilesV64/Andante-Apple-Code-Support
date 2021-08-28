//
//  CenterLoadingController.swift
//  Andante
//
//  Created by Miles Vinson on 11/15/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit


class CenterLoadingViewController: UIViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private let bgView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    enum LoadingStyle {
        case progress, indefinite
    }
    
    private var progressBar: UIProgressView?
    private var activityIndicator: UIActivityIndicatorView?
    
    public var progress: Float = 0 {
        didSet {
            progressBar?.progress = progress
        }
    }
    
    private let textView = UITextView()
    
    private var style: LoadingStyle = .indefinite
    
    public var text: String? {
        didSet {
            textView.text = text ?? ""
            view.setNeedsLayout()
        }
    }
        
    convenience init(style: LoadingStyle) {
        self.init()
        
        self.style = style
        if style == .indefinite {
            activityIndicator = UIActivityIndicatorView()
        } else {
            progressBar = UIProgressView()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
                        
        if let bar = progressBar {
            bgView.contentView.addSubview(bar)
            bar.tintColor = Colors.purple
        } else if let indicator = activityIndicator {
            bgView.contentView.addSubview(indicator)
            indicator.color = Colors.text
        }
        
        textView.isUserInteractionEnabled = false
        textView.font = Fonts.regular.withSize(15)
        textView.textColor = Colors.lightText
        textView.textContainerInset = UIEdgeInsets(
            top: 0, left: 25, bottom: 0, right: 25)
        textView.textAlignment = .center
        textView.backgroundColor = .clear
        bgView.contentView.addSubview(textView)
        
        bgView.roundCorners(12)
        bgView.clipsToBounds = true
        view.addSubview(bgView)
        
    }
    
    public func close(success: Bool) {
        if success {
            UIView.animate(withDuration: 0.25) {
                self.activityIndicator?.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                self.activityIndicator?.alpha = 0
            }
            
            let imgView = UIImageView(image: UIImage(name: "checkmark", pointSize: 50, weight: .regular))
            imgView.setImageColor(color: Colors.text.withAlphaComponent(0.75))
            imgView.sizeToFit()
            imgView.center = activityIndicator?.center ?? bgView.bounds.center
            imgView.alpha = 0
            imgView.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
            bgView.contentView.addSubview(imgView)
            UIView.animate(withDuration: 0.4, delay: 0.15, usingSpringWithDamping: 0.92, initialSpringVelocity: 0, options: .curveEaseOut) {
                imgView.alpha = 1
                imgView.transform = .identity
            } completion: { (complete) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.close()
                }
            }
        }
        else {
            self.close()
        }
        

    }
    
    public var closeAction: (()->())?
    
    public func close() {
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 0
            self.bgView.alpha = 0
            self.bgView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        } completion: { (complete) in
            self.dismiss(animated: false, completion: {
                [weak self] in
                guard let self = self else { return }
                self.closeAction?()
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        bgView.alpha = 0
        bgView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.bgView.alpha = 1
            self.bgView.transform = .identity
            self.view.backgroundColor = Colors.dimColor
        } completion: { (complete) in }

        
        activityIndicator?.startAnimating()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        bgView.bounds.size = CGSize(width: 180, height: 180)
        bgView.center = view.bounds.center
        
        let height = textView.sizeThatFits(bgView.bounds.size).height
        textView.frame = CGRect(
            x: 0, y: 24,
            width: bgView.bounds.width,
            height: height)
                 
        
        progressBar?.contextualFrame = CGRect(
            x: 30, y: textView.frame.maxY + 20,
            width: bgView.bounds.width - 60,
            height: 40)
        
        activityIndicator?.contextualFrame = CGRect(
            x: bgView.bounds.midX - 40, y: bgView.bounds.midY - 40,
            width: 80,
            height: 80)
        
    }
    
}
