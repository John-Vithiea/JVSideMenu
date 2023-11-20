/*
 * JVSideMenu
 * v1.0
 *
 * Copyright (c) 2021 Vithiea Hor (John)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit


public enum JVSideMenuState {
    case opened
    case closed
}

open class JVSideMenu: NSObject {
    
    /// The controller that used to animate Menu
    public var rootViewController: UIViewController!
    private var coverMaskView: UIView = UIView()
    
    // --- left menu
    public var leftMenuController: UIViewController?
    private var leftMenuConstraint: NSLayoutConstraint?
    private var sideMenuWidthConstraint: NSLayoutConstraint?
    
    public var maxLeftWidth: CGFloat = 0.8
    public var absoluteLeftWidth: CGFloat {
        return UIScreen.main.bounds.width * maxLeftWidth
    }
    
    // option
    public var isGestureEnabled: Bool = true {
        didSet {
            panGesture.isEnabled = isGestureEnabled
        }
    }
    
    private let window = UIApplication.shared.keyWindow
    private let transitionDuration: TimeInterval = 0.35
    private var leftState: JVSideMenuState = .closed
    
    // color alpha component of cover mask view per x, max 0.5
    private var alphaX: CGFloat {
        return 0.5 / self.absoluteLeftWidth
    }
    
    lazy private var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panningView))
    
    
    // MARK: ----- Initialization
    public static let shared = JVSideMenu()
    private override init() {}
    
    public func set(leftMenu:UIViewController, rootController:UIViewController) {
        self.rootViewController = rootController
        self.window?.addSubview(leftMenu.view)
        
        maxLeftWidth = getWidth()
        self.leftMenuController = leftMenu
        self.constraintForLeft()
        self.leftState = .closed
        
        self.setupCoverView()
    }
    
    private func setupCoverView() {
        // hide mask view from being interacted
        self.coverMaskView.isHidden = true
        self.coverMaskView.backgroundColor = UIColor.black.withAlphaComponent(0)
        self.window?.addSubview(self.coverMaskView)
        self.fillParent(subview: self.coverMaskView)
        
        self.window?.addGestureRecognizer(panGesture)
        self.coverMaskView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnMaskView)))
        
        DispatchQueue.main.async {
            self.window?.bringSubviewToFront(self.coverMaskView)
            if let leftmenu = self.leftMenuController?.view {
                self.window?.bringSubviewToFront(leftmenu)
            }
        }
    }
    
    private func getWidth() -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIScreen.main.bounds.width <= 1000 ? 0.65 : 0.5
        }
        return 0.8
    }
    
    // MARK: Gesture Recognizer
    @objc private func didTapOnMaskView() {
        self.closeLeft(completion: nil)
    }
    
    @objc private func panningView(recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            handlePanningTransition(x: recognizer.translation(in: self.window).x, constraint:self.leftMenuConstraint!)
            break
        case .ended:
            self.handlePanningEnd()
            break
        default:
            break
        }
    }
    
    private func handlePanningEnd() {
        switch self.leftState {
        case .opened:
            if self.leftMenuConstraint!.constant <= (-self.absoluteLeftWidth/2) {self.closeLeft(completion:nil)} else {self.openLeft(completion:nil)}
        case .closed:
            if self.leftMenuConstraint!.constant >= (-self.absoluteLeftWidth/2) {self.openLeft(completion:nil)} else {self.closeLeft(completion:nil)}
        }
    }
    
    private func handlePanningTransition(x:CGFloat, constraint:NSLayoutConstraint) {
        var alpha: CGFloat = 0.0
        var xMoved: CGFloat = 0.0
        if self.leftState == .opened {
            // close action
            xMoved = x
            alpha = self.alphaX * (self.absoluteLeftWidth + xMoved)
        } else {
            // open action
            xMoved = -self.absoluteLeftWidth + x
            alpha = self.alphaX * x
        }
        
        if xMoved >= 0 {return}
        constraint.constant = xMoved
        
        self.coverMaskView.isHidden = false
        self.coverMaskView.backgroundColor = UIColor.black.withAlphaComponent(alpha)
    }
    
    
    // MARK: Transitions
    public func push(_ controller: UIViewController) {
        self.closeLeft { [weak self] in
            guard let self = self else { return }
            if (self.rootViewController.isKind(of: UINavigationController.self)){
                (self.rootViewController as! UINavigationController).pushViewController(controller, animated: true)
            } else if (self.rootViewController.isKind(of: UITabBarController.self)) {
                handleTabBar(tabbarVC: self.rootViewController as! UITabBarController)
            } else {
                self.rootViewController.navigationController?.pushViewController(controller, animated: true)
            }
        }
        
        func handleTabBar(tabbarVC: UITabBarController) {
            if let navigation = tabbarVC.navigationController {
                navigation.pushViewController(controller, animated: true)
                return
            }
            
            guard let selectedVC = tabbarVC.selectedViewController else { return }
            if selectedVC.isKind(of: UINavigationController.self) {
                (selectedVC as! UINavigationController).pushViewController(controller, animated: true)
            } else {
                selectedVC.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    public func openLeft(completion:(()->Void)?) {
        if let leftMenu = self.leftMenuConstraint {
            self.openMenu(constraint: leftMenu, completed: { [weak self] in
                guard let self = self else { return }
                self.leftState = .opened
                
                if let handler = completion {
                    handler()
                }
            })
        }
    }
    
    public func closeLeft(completion:(()->Void)?) {
        self.closeMenu(constraint: self.leftMenuConstraint!, constant: -self.absoluteLeftWidth, completed: { [weak self] in
            guard let self = self else { return }
            self.leftState = .closed
            
            if let handler = completion {
                handler()
            }
        })
    }
    
    public func invalidateLayout() {
        self.maxLeftWidth = self.getWidth()
        self.sideMenuWidthConstraint?.constant = self.absoluteLeftWidth
        if self.leftState == .closed {
            self.leftMenuConstraint?.constant = -self.absoluteLeftWidth
        }
    }
    
    private func openMenu(constraint:NSLayoutConstraint, completed:@escaping()->Void) {
        UIView.animate(withDuration: self.transitionDuration, animations: {
            constraint.constant = 0
            self.window?.layoutIfNeeded()
            
            // hidden has no animation. unhide here to see fade in animation
            self.coverMaskView.isHidden = false
            self.coverMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        }) { (finished) in
            completed()
        }
    }
    
    private func closeMenu(constraint:NSLayoutConstraint, constant:CGFloat, completed:@escaping()->Void) {
        UIView.animate(withDuration: self.transitionDuration, animations: {
            constraint.constant = constant
            self.window?.layoutIfNeeded()
            
            self.coverMaskView.backgroundColor = UIColor.black.withAlphaComponent(0)
        }) { (finished) in
            // hidden has no animation. set hidden in animate block cause view to hide before animation start.
            self.coverMaskView.isHidden = true
            completed()
        }
    }
    
    // MARK: - Constraints
    private func constraintForLeft() {
        self.leftMenuConstraint = self.constraint(view: self.leftMenuController!.view,
                                                  superView: self.leftMenuController!.view.superview!,
                                                  width: self.absoluteLeftWidth,
                                                  attributeItem: .leading)
    }
    
    private func constraint(view:UIView, superView:UIView, width:CGFloat, attributeItem:NSLayoutConstraint.Attribute) -> NSLayoutConstraint {
        // this constraint would be Leading or Trailing
        let leftOrRight = NSLayoutConstraint(item: view, attribute: attributeItem, relatedBy: .equal, toItem: superView, attribute: attributeItem, multiplier: 1.0, constant: -width)
        self.sideMenuWidthConstraint = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: width)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: superView.topAnchor),
            view.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
            leftOrRight,
            self.sideMenuWidthConstraint!
        ])
        
        // return back to caller to store in property for later use in Transitions section
        return leftOrRight
    }
    
    private func fillParent(subview:UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        let superView = subview.superview!
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[subview]-(0)-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview": subview]))
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[subview]-(0)-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview": subview]))
    }
}

