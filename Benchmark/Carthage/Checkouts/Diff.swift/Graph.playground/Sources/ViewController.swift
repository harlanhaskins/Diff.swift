//
//  ViewController.swift
//  Graph
//
//  Created by Wojciech Czekalski on 21.03.2016.
//  Copyright © 2016 wczekalski. All rights reserved.
//

import UIKit

public class GraphViewController: UIViewController {
    let dValueLabel = UILabel()
    let kValueLabel = UILabel()
    lazy var graphView: UIView = {
        let view = UIView()
        view.backgroundColor = self.backgroundColor()
        return view
    }()
    lazy var slider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(sliderDidChange), forControlEvents: .ValueChanged)
        return slider
    }()
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.graphView, self.dValueLabel, self.kValueLabel, self.slider])
        stackView.frame = self.view.bounds
        stackView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        stackView.layoutMarginsRelativeArrangement = true
        stackView.axis = .Vertical
        return stackView
    }()

    var diffStrings = ("", "") {
        didSet {
            view.setNeedsLayout()
        }
    }
    var graph: Graph {
        let grid = Grid(x: diffStrings.0.length(), y: diffStrings.1.length())
        return Graph(grid: grid, bounds: CGRectInset(graphView.frame, 50, 50))
    }
    var arrows: [CAShapeLayer] = [] {
        didSet {
            oldValue.forEach {$0.removeFromSuperlayer()}
            arrows.forEach {graphView.layer.addSublayer($0)}
        }
    }
    var traces: [Trace] {
        return Array(diffStrings.0.characters).diffTraces(Array(diffStrings.1.characters))
    }
    
    func display(range: Range<Int>? = nil) {
        graphView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        var displayedTraces = traces
        if let range = range {
            displayedTraces = Array(displayedTraces[range])
            slider.value = Float(range.endIndex-1)/Float(traces.count-1)
        } else {
            slider.value = 1
        }
        
        graph.gridLayers().forEach { graphView.layer.addSublayer($0) }
        arrows = displayedTraces.map { $0.shapeLayer(on: graph) }
        
        let labels1 = diffStrings.0.characterLabels(withFrames: graph.rects(row: -1))
        let labels2 = diffStrings.1.characterLabels(withFrames: graph.rects(column: -1))
        (labels1 + labels2).forEach { graphView.addSubview($0) }
        
        if let maxElement = displayedTraces.maxElement({$0.D < $1.D}) {
            dValueLabel.text = "Number of differences: \(maxElement.D)"
            kValueLabel.text = "k value \(maxElement.k())"
        }
    }
    
    func sliderDidChange(sender: UISlider) {
        let maxIndex = Int(sender.value * Float(traces.count-1))
        display(0...maxIndex)
    }
    
    public override func viewDidLoad() {
        view.backgroundColor = backgroundColor()
        view.addSubview(stackView)
    }
    
    public override func viewDidLayoutSubviews() {
        display()
    }

    func backgroundColor() -> UIColor {
        return UIColor(red: 65/255, green: 153/255, blue: 1, alpha: 1)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(string1: String, string2: String) {
        super.init(nibName: nil, bundle: nil)
        diffStrings = (string1, string2)
    }
}

extension Trace {
    func arrow(on graph: Graph) -> Arrow {
        let from = graph.coordinates(at: self.from)
        let to = graph.coordinates(at: self.to)
        
        let translatedCoordinates: (from: CGPoint, to: CGPoint) = {
            let yDelta = (to.y-from.y)/20
            let xDelta = (to.x-from.x)/20
            
            switch type() {
            case .Deletion:
                return (CGPoint(x: from.x+xDelta, y: from.y), CGPoint(x: to.x-xDelta, y: to.y))
            case .Insertion:
                return (CGPoint(x: from.x, y: from.y+yDelta), CGPoint(x: to.x, y: to.y-yDelta))
            case .MatchPoint:
                return (CGPoint(x: from.x+xDelta, y: from.y+yDelta), CGPoint(x: to.x-xDelta, y: to.y-yDelta))
            }
        }()
        return Arrow(from: translatedCoordinates.from, to: translatedCoordinates.to, tailWidth: 6, headWidth: 12, headLength: 10)
    }
    
    func shapeLayer(on graph: Graph) -> CAShapeLayer {
        let arrowLayer = UIBezierPath(arrow: arrow(on: graph)).shapeLayer()
        
        switch type() {
        case .Deletion:
            arrowLayer.fillColor = UIColor.redColor().CGColor
        case .Insertion:
            arrowLayer.fillColor = UIColor.greenColor().CGColor
        case .MatchPoint:
            arrowLayer.fillColor = UIColor.whiteColor().CGColor
        }
        return arrowLayer

    }
}