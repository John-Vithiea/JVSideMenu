//
//  JVSideMenu.swift
//  v1.0
//
//  Created by Vithiea Hor on 11/29/19.
//  Copyright © 2019 John-Vithiea. All rights reserved.
//

import UIKit

public enum JVSideMenuState {
    case opened
    case closed
}

public class JVSideMenu: NSObject {
    
    // used for view transition after selected an item
    var rootViewController: UIViewController!
    private var coverMaskView: UIView = UIView()
    
    // --- left menu
    var leftMenuController: UIViewController?
    private var leftMenuConstraint: NSLayoutConstraint?
    
    var maxLeftWidth: CGFloat = 0.8
    var absoluteLeftWidth: CGFloat {
        return UIScreen.main.bounds.width * maxLeftWidth
    }
    
    // --- right menu
//    var rightMenuController: UIViewController?
//    var rightMenuContraint: NSLayoutConstraint?
    
//    var maxRightWidth: CGFloat = 0.8
//    var absoluteRightWidth: CGFloat {
//        return UIScreen.main.bounds.width * maxRightWidth
//    }
    
    // option
    var isGestureEnabled: Bool = true {
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
    
    public func setup(leftMenu:UIViewController, rootController:UIViewController) {
        self.rootViewController = rootController
        self.window?.addSubview(leftMenu.view)
        
        self.leftMenuController = leftMenu
        self.constraintForLeft()
        self.leftState = .closed
        
        self.setupCoverView()
    }
    
    
//    public func setup(rightMenu:UIViewController, rootController:UIViewController) {
//        self.rootViewController = rootController
//        self.window?.addSubview(rightMenu.view)
//
//        self.rightMenuController = rightMenu
//        self.constraintForRight()
//
//        self.setupCoverView()
//    }
    
    private func setupCoverView() {
        // hide mask view from being interacted
        self.coverMaskView.isHidden = true
        self.coverMaskView.backgroundColor = UIColor.black.withAlphaComponent(0)
        self.rootViewController.view.addSubview(self.coverMaskView)
        self.fillParent(subview: self.coverMaskView)
        
        self.window?.addGestureRecognizer(panGesture)
        self.coverMaskView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnMaskView)))
    }
    
    // MARK: Gesture Recognizer
    @objc
    private func didTapOnMaskView() {
        self.closeLeft{}
    }
    
    @objc
    private func panningView(recognizer:UIPanGestureRecognizer) {
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
            if self.leftMenuConstraint!.constant <= (-self.absoluteLeftWidth/2) {self.closeLeft{}} else {self.openLeft{}}
        case .closed:
            if self.leftMenuConstraint!.constant >= (-self.absoluteLeftWidth/2) {self.openLeft{}} else {self.closeLeft{}}
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
        self.closeLeft {
            if self.rootViewController.isKind(of: UIViewController.self) {
                (self.rootViewController as! UINavigationController).pushViewController(controller, animated: true)
            }else{
                self.rootViewController.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    public func openLeft(_ completed:@escaping()->Void) {
        self.openMenu(constraint: self.leftMenuConstraint!, completed: {
            self.leftState = .opened
        })
    }
    
    public func closeLeft(_ completed:@escaping()->Void) {
        self.closeMenu(constraint: self.leftMenuConstraint!, constant: -self.absoluteLeftWidth, completed: {
            self.leftState = .closed
            completed()
        })
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
    
//    private func constraintForRight() {
//        self.rightMenuContraint = self.constraint(view: self.rightMenuController!.view,
//                                                  superView: self.rightMenuController!.view.superview!,
//                                                  width: self.absoluteRightWidth,
//                                                  attributeItem: .trailing)
//    }
    
    private func constraint(view:UIView, superView:UIView, width:CGFloat, attributeItem:NSLayoutConstraint.Attribute) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        superView.addConstraint(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: superView, attribute: .top, multiplier: 1.0, constant: 0))
        superView.addConstraint(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: superView, attribute: .bottom, multiplier: 1.0, constant: 0))
        superView.addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: width))
        
        // this constraint would be Leading or Trailing
        let constraint = NSLayoutConstraint(item: view, attribute: attributeItem, relatedBy: .equal, toItem: superView, attribute: attributeItem, multiplier: 1.0, constant: -width)
        superView.addConstraint(constraint)
        
        // return back to caller to store in property for later use in Transitions section
        return constraint
    }
    
    private func fillParent(subview:UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        let superView = subview.superview!
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[subview]-(0)-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview": subview]))
        superView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[subview]-(0)-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["subview": subview]))
    }
}

