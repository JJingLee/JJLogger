//
//  ViewController.swift
//  JJLogger
//
//  Created by 李杰駿 on 2020/8/15.
//  Copyright © 2020 李杰駿. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let table = UITableView()
    let headerView = JJCellItem()
    let footerView = JJCellItem()
    var logger : scrollViewLogger?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        logger = scrollViewLogger(table)
        self.view.addSubview(table)
        table.frame = self.view.bounds
        table.delegate = self
        table.dataSource = self
        table.register(JJCell.self, forCellReuseIdentifier: "cell")
        
        
        self.headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 150)
        self.headerView.backgroundColor = .red
        self.headerView.name = "header"
        self.table.tableHeaderView = headerView
        
        
        self.footerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 150)
        self.footerView.backgroundColor = .red
        self.footerView.name = "footer"
        self.table.tableFooterView = footerView
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(gotoNext))
        self.footerView.addGestureRecognizer(tap)
        
        logger?.appendLoggerViewIfNotExist(headerView)
        logger?.appendLoggerViewIfNotExist(footerView)
    }
    
    @objc func gotoNext() {
        let vc = ViewController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    deinit {
        logger?.despose()
        print("deinit \(type(of: self))")
    }
    private var isGoAndBack = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isGoAndBack {
            self.logger?.resendEvent()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isGoAndBack = true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? JJCell else {
            return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        }
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let loggerCell = cell as? JJCell else {return}
        logger?.appendLoggerViewIfNotExist(loggerCell.cellItem)
        loggerCell.cellItem.name = "cell \(indexPath.row)"
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}

//MARK : test cell
class JJCell : UITableViewCell {
    var cellItem : JJCellItem = JJCellItem()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(cellItem)
        cellItem.frame = self.contentView.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cellItem.frame = self.contentView.bounds
    }
    
}

class JJCellItem : UIView, JJLoggerViewProtocol {
    var name: String? {
        get {
            return self.label.text
        }
        set {
            self.label.text = newValue
        }
    }
    var label = UILabel()
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.label.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


//MARK: - JJLogger
public class JJLoger {
    public class func clickEvent(with name:String) {
        print("clickEvent \(name)")
    }
    
    static public var unrepeatTime : TimeInterval = 1
    static var exposureEventCache = NSCache<NSString,NSDate>()
    public class func explosureEvent(with name:String) {
        let current = NSDate()
        if let time = exposureEventCache.object(forKey: name as NSString) {
            guard (current.timeIntervalSince1970 - time.timeIntervalSince1970) > unrepeatTime else {
                return
            }
        }
        exposureEventCache.setObject(current, forKey: name as NSString)
        print("explosureEvent \(name)")
    }
    public class func pageEvent(with name:String) {
        print("pageEvent \(name)")
    }
}

//MARK: ScrollView listeners
public class scrollViewLogger {
    weak var _scrollView : UIScrollView?
    private var listenerViews : [UIView] = []
    private var subviewsIsExposing : [Bool] = []
    private var scrollObservation : NSKeyValueObservation?
    
    deinit {
        print("deinit \(type(of: self))")
    }
    
    public init(_ scrollview : UIScrollView) {
        _scrollView = scrollview
        if #available(iOS 11.0, *) {
            _scrollView?.contentInsetAdjustmentBehavior = .never
        }
        listensScroll()
    }
    
    public func appendLoggerViewIfNotExist(_ view : UIView) {
        defer { objc_sync_exit(self.listenerViews) }
        objc_sync_enter(self.listenerViews)
        guard !listenerViews.contains(view) else {return}
        listenerViews.append(view)
        subviewsIsExposing.append(false)
    }
    
    private func getExposureState(_ index : Int)->Bool {
        defer { objc_sync_exit(self.subviewsIsExposing) }
        objc_sync_enter(self.subviewsIsExposing)
        guard self.subviewsIsExposing.count > index else { return false }
        return self.subviewsIsExposing[index]
    }
    
    private func setExposureState(_ index : Int, value : Bool) {
        defer { objc_sync_exit(self.subviewsIsExposing) }
        objc_sync_enter(self.subviewsIsExposing)
        guard self.subviewsIsExposing.count > index else { return }
        self.subviewsIsExposing[index] = value
    }
    
    private func listensScroll() {
        let observation = _scrollView?.observe(\.contentOffset, options: .new, changeHandler: { [weak self](scroll, observedChange) in
            guard let self = self else {return}
            self.sendEvent(with: observedChange.newValue)
        })
        self.scrollObservation = observation
    }
    
    public func resendEvent() {
        objc_sync_enter(self.subviewsIsExposing)
        self.subviewsIsExposing = Array<Bool>.init(repeating: false, count: self.subviewsIsExposing.count)
        objc_sync_exit(self.subviewsIsExposing)
        self.sendEvent(with: self._scrollView?.contentOffset)
    }
    
    private func sendEvent(with offset:CGPoint?) {
        let newVal = offset
        let scrollSize = self._scrollView?.bounds.size
        let maxX : CGFloat = (newVal?.x ?? 0) + (scrollSize?.width ?? 0)
        let minX : CGFloat = newVal?.x ?? 0
        let maxY : CGFloat = (newVal?.y ?? 0) + (scrollSize?.height ?? 0)
        let minY : CGFloat = newVal?.y ?? 0
        
        var currentIndex = 0
        objc_sync_enter(self.listenerViews)
        for subV in self.listenerViews {
            let zeroCoor = subV.convert(CGPoint.zero, to: self._scrollView)
            let maxCoor = CGPoint(x: zeroCoor.x+subV.bounds.width, y: zeroCoor.y+subV.bounds.height)
            let subvSize = subV.bounds.size
            let xBuffer : CGFloat = subvSize.width * 0.3
            let yBuffer : CGFloat = subvSize.height * 0.3
            let xIntheRange = (zeroCoor.x >= minX && zeroCoor.x < (maxX-xBuffer)) || (maxCoor.x > (minX+xBuffer) && maxCoor.x <= maxX)
            let yIntheRange = (zeroCoor.y >= minY && zeroCoor.y < (maxY-yBuffer)) || (maxCoor.y > minY && maxCoor.y <= (maxY+yBuffer))
            if xIntheRange && yIntheRange {
            // if is exposure
                guard self.subviewsIsExposing.count > currentIndex else { continue }
                if (!self.getExposureState(currentIndex) && (((subV as? JJLoggerViewProtocol)?.name) != nil) ) {
                    guard let logname = (subV as? JJLoggerViewProtocol)?.name else { continue }
                    JJLoger.explosureEvent(with: logname)
                    self.setExposureState(currentIndex, value: true)
                }
            }else {
            //if not exposure
                guard self.subviewsIsExposing.count > currentIndex else { continue }
                self.setExposureState(currentIndex, value: false)
            }
            
            currentIndex += 1
        }
        objc_sync_exit(self.listenerViews)
    }
    
    public func despose() {
        listenerViews = []
        self.scrollObservation?.invalidate()
        self.scrollObservation = nil
    }
}

protocol JJLoggerViewProtocol : UIView {
    var name : String? { get }
}


//MARK: - clickers
class JJLogView : UIView {
    
    var name : String = ""
    override func didMoveToWindow() {
        super.didMoveToWindow()
//        print("\(name) didMoveToWindow")
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        print("point inside.")
        
        let apoint = UIApplication.shared.keyWindow?.convert(CGPoint.init(x: 0, y: 0), from: self)
        
        if point.y >= ((UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0) + 44) - self.bounds.height ||
        point.y < (UIApplication.shared.keyWindow?.bounds.size.height ?? 0) {
//            print("\(name) point : \(String(describing: apoint))")
        }
        
        
        return super.point(inside: point, with: event)
    }
    
}
