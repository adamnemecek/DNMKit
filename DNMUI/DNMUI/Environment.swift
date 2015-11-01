//
//  Environment.swift
//  denm_view
//
//  Created by James Bean on 9/20/15.
//  Copyright © 2015 James Bean. All rights reserved.
//

import QuartzCore
import DNMModel
import DNMView

public class Environment: UIView {
    
    public var viewSelector: RadioGroupPanelVertical!
    public var viewSelectorDot: UIView!
    
    public var views: [PerformerView] = []
    public var viewByID: [String: PerformerView] = [:]
    public var currentView: PerformerView?
    
    public var pages: [Page] = []
    public var currentPage: Page?
    public var currentPageIndex: Int?
    
    public var systems: [System] = []
    
    public var durationNodes: [DurationNode] = []
    public var measures: [MeasureView] = []
    public var tempoMarkings: [TempoMarking] = []
    public var rehearsalMarkings: [RehearsalMarking] = []
    
    public var g: CGFloat = 10 // ?! // hack
    public var beatWidth: CGFloat = 110 // ?! // hack
    
    public var page_pad: CGFloat = 25
    
    public var componentTypesShownByID: [String : [String]] = [:]

    public var iIDsAndInstrumentTypesByPID: [[String : [(String, InstrumentType)]]] = []
    
    public var viewIDs: [String] = []
    
    public init(scoreInfo: ScoreInfo) {
        super.init(frame: CGRectZero)
        self.iIDsAndInstrumentTypesByPID = scoreInfo.iIDsAndInstrumentTypesByPID
        self.measures = makeMeasureViewsWithMeasures(scoreInfo.measures)
        self.tempoMarkings = scoreInfo.tempoMarkings
        self.rehearsalMarkings = scoreInfo.rehearsalMarkings // createRehearsalMarkingsWith..._model
        self.durationNodes = scoreInfo.durationNodes
    }
    
    private func makeMeasureViewsWithMeasures(measures_model: [Measure]) -> [MeasureView] {
        var measures: [MeasureView] = []
        for measure_model in measures_model {
            let duration = measure_model.duration
            let offsetDuration = measure_model.offsetDuration
            let measure = MeasureView(duration: duration)
            measure.hasTimeSignature = measure_model.hasTimeSignature
            measures.append(measure)
        }
        return measures
    }
    
    /*
    public init(
        measures: [Measure] = [],
        durationNodes: [DurationNode] = [],
        iIDsAndInstrumentTypesByPID: [[String : [(String, InstrumentType)]]] = [],
        viewerID: String = ""
    )
    {
        super.init(frame: CGRectZero)
        self.measures = measures
        self.durationNodes = durationNodes
        self.viewerID = viewerID
        self.iIDsAndInstrumentTypesByPID = iIDsAndInstrumentTypesByPID
        
        let gR = UITapGestureRecognizer(target: self, action: "didTap")
        addGestureRecognizer(gR)
    }
    */

    public override init(frame: CGRect) { super.init(frame: frame) }
    public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    public func didTap() {
        
    }
    
    public func createViews() {

        viewIDs = []
        for performerArray in iIDsAndInstrumentTypesByPID {
            for (id, arrayOfIIDsAndInstrumentTypes) in performerArray {
               viewIDs.append(id)
            }
        }
        viewIDs.append("omni")
        
        for id in viewIDs {
            let systems = makeSystemsWithViewerID(id)
            let view = PerformerView(id: id, systems: systems)
            viewByID[id] = view
            views.append(view)
        }
    }
    
    public func goToViewWithID(id: String) {
        if let view = viewByID[id] {
            for subview in subviews { subview.removeFromSuperview() }
            addSubview(view)
            currentView = view
            setFrame()
        }
    }
    
    public func setFrame() {
        if let currentView = currentView { frame = currentView.frame }
    }
    
    // MARK: Page Navigation
    public func goToLastPage() {
        currentView?.goToLastPage()
    }
    
    public func goToFirstPage() {
        currentView?.goToFirstPage()
    }
    
    public func goToPage(number number: Int) {
        currentView?.goToPageAtIndex(number - 1)
    }
    
    private func goToPage(index index: Int) {
        currentView?.goToPageAtIndex(index)
    }
    
    public func goToNextPage() {
        currentView?.goToNextPage()
    }
    
    public func goToPreviousPage() {
        currentView?.goToPreviousPage()
    }
    
    public func build() {
        createViews()
        goToViewWithID("omni") // set default view
        goToFirstPage()
    }
    
    // manageSpanners()
    public func manageHorizontalLigatures() {
        // DMLigature
        // DurationalExtension
        // Slur
    }

    /*
    public func createSystems() {
        self.systems = makeSystems()
    }
    */
    
    public func createPages() {
        self.pages = makePages()
    }
    
    public func makeSystemsWithViewerID(id: String) -> [System] {
        
        // set properties of measure
        for (m, measure) in measures.enumerate() {
            measure.number = m + 1
            measure.beatWidth = beatWidth
        }
        
        let maximumWidth = UIScreen.mainScreen().bounds.width - 2 * page_pad
        var systems: [System] = []
        var measureIndex: Int = 0
        var accumDuration: Duration = DurationZero
        while measureIndex < measures.count {
            let measureRange = MeasureView.rangeFromMeasures(measures,
                startingAtIndex: measureIndex, constrainedByMaximumTotalWidth: maximumWidth
            )
            
            // what is g here?
            let system = System(g: g, beatWidth: 110, viewerID: id)
            system.iIDsAndInstrumentTypesByPID = iIDsAndInstrumentTypesByPID
            system.offsetDuration = accumDuration
            system.setMeasuresWithMeasures(measureRange)

            // encapsulate: internal
            let start = system.offsetDuration
            let stop = system.offsetDuration + system.totalDuration // DurationSpan.duration...
            let durationNodeRange = DurationNode.rangeFromDurationNodes(durationNodes,
                afterDuration: start, untilDuration: stop
            )
            
            system.setDurationNodesWithDurationNodes(durationNodeRange)
            systems.append(system)
            
            // encapsulate: increment shit
            let lastMeasureIndex: Int = measures.indexOf(measureRange.last!)!
            measureIndex = lastMeasureIndex + 1
            accumDuration += system.totalDuration // DurationSpan.stopDuration
        }
        
        // PRELIMINARY BUILD
        for system in systems {
            system.build()
        }
        
        // ADD FRAYED LIGATURES, ADD DMNODES IF NECESSARY
        manageDMLigaturesForSystems(systems)
        manageSlursForSystems(systems)
        
        // COMPLETE BUILD
        for system in systems {
            
            // encapsulate
            // make show only view id, unless omni view
            if id != "omni" {
                let ids_complement = viewIDs.filter({$0 != id})
                for id in ids_complement { system.componentTypesShownByID[id] = [] }
            }
            
            system.arrangeNodesWithComponentTypesPresent() // need to get slurs in there somehow
            system.createStems()
            
            
            // manage tempoMarkings
            for tempoMarking in tempoMarkings {
                if tempoMarking.offsetDuration >= system.offsetDuration &&
                    tempoMarking.offsetDuration < system.totalDuration
                {
                    let durationFromSystemStart = tempoMarking.offsetDuration - system.offsetDuration
                    //let x = graphicalWidth(duration: durationFromSystemStart, beatWidth: beatWidth) + system.infoStartX
                    let x = durationFromSystemStart.width(beatWidth: beatWidth) + system.infoStartX
                    
                    system.addTempoMarkingWithValue(tempoMarking.value, andSubdivisionLevel: tempoMarking.subdivisionLevel, atX: x)
                }
            }
            
            //
            for rehearsalMarking in rehearsalMarkings {
                if rehearsalMarking.offsetDuration >= system.offsetDuration &&
                    rehearsalMarking.offsetDuration < system.totalDuration
                {
                    let durationFromSystemStart = rehearsalMarking.offsetDuration
                        - system.offsetDuration
                    
                    let x = durationFromSystemStart.width(beatWidth: beatWidth) + system.infoStartX
                    
                    /*
                    let x = graphicalWidth(duration: durationFromSystemStart, beatWidth: beatWidth)
                        + system.infoStartX
                    */
                    
                    if let type = RehearsalMarkingType(rawValue: rehearsalMarking.type) {
                        system.addRehearsalMarkingWithIndex(rehearsalMarking.index,
                            type: type, atX: x
                        )
                    }
                }
            }
        }
        return systems
    }
    
    
    public func makePages() -> [Page] {

        var maximumHeight = UIScreen.mainScreen().bounds.height - 2 * page_pad

        var pages: [Page] = []
        var systemIndex: Int = 0
        
        while systemIndex < systems.count {
            let systemRange = System.rangeFromSystems(systems,
                startingAtIndex: systemIndex, constrainedByMaximumTotalHeight: maximumHeight
            )

            // clean up initialization
            let page = Page(systems: systemRange)
            //page.left = page_pad
            page.top = page_pad // hack
            page.build()

            
            // make conditional if can't make system cuz its too long
            let lastSystemIndex = systems.indexOfObject(page.systems.last!)!
            systemIndex = lastSystemIndex + 1
            pages.append(page)
        }
        return pages
    }
    
    
    public func manageSlursForSystems(systems: [System]) {
        struct SlurSpan {
            var systemStartIndex: Int?
            var systemStopIndex: Int?
        }
    }
    
    public func manageDMLigaturesForSystems(systems: [System]) {
        
        // encapsulate: create ligature spans
        struct DMLigatureSpan {
            var systemStartIndex: Int?
            var systemStopIndex: Int?
            var startIntValue: Int?
            var stopIntValue: Int?
            
            init(systemStartIndex: Int, startIntValue: Int) {
                self.systemStartIndex = systemStartIndex
                self.startIntValue = startIntValue
            }
            
            init(systemStopIndex: Int, stopIntValue: Int) {
                self.systemStartIndex = systemStopIndex
                self.stopIntValue = stopIntValue
            }
            
            mutating func setSystemStopIndex(systemStopIndex: Int, stopIntValue: Int) {
                self.systemStopIndex = systemStopIndex
                self.stopIntValue = stopIntValue
            }
            
            mutating func setSystemStartIndex(systemStartIndex: Int, startIntValue: Int) {
                self.systemStartIndex = systemStartIndex
                self.startIntValue = startIntValue
            }
        }
        
        var dmLigatureSpansByID: [String : [DMLigatureSpan]] = [:]

        for (s, system) in systems.enumerate() {
            for (id, dmNode) in system.dmNodeByID {
                for ligature in dmNode.ligatures {
                    if ligature.hasBeenBuilt { continue }
                    if ligature.initialDynamicMarkingIntValue == nil {
                        if let finalIntValue = ligature.finalDynamicMarkingIntValue {
                            if dmLigatureSpansByID[id] == nil {
                                let dmLigatureSpan = DMLigatureSpan(
                                    systemStopIndex: s, stopIntValue: finalIntValue
                                )
                                dmLigatureSpansByID[id] = [dmLigatureSpan]
                            }
                            else {
                                for (d, var dmLigatureSpan) in dmLigatureSpansByID[id]!.enumerate() {
                                    if dmLigatureSpan.stopIntValue == nil {
                                        dmLigatureSpan.setSystemStopIndex(s, stopIntValue: finalIntValue)
                                        dmLigatureSpansByID[id]!.removeAtIndex(d)
                                        dmLigatureSpansByID[id]!.insert(dmLigatureSpan, atIndex: d)
                                        break
                                    }
                                }
                            }
                        }
                    }
                    else {
                        if let initialValue = ligature.initialDynamicMarkingIntValue {
                            if dmLigatureSpansByID[id] == nil {
                                // create
                                let dmLigatureSpan = DMLigatureSpan(
                                    systemStartIndex: s, startIntValue: initialValue
                                )
                                dmLigatureSpansByID[id] = [dmLigatureSpan]
                            }
                            else {
                                // find and append
                                for (d, var dmLigatureSpan) in dmLigatureSpansByID[id]!.enumerate() {
                                    if dmLigatureSpan.startIntValue == nil {
                                        dmLigatureSpan.setSystemStartIndex(s, startIntValue: initialValue)
                                        dmLigatureSpansByID[id]!.removeAtIndex(d)
                                        dmLigatureSpansByID[id]!.insert(dmLigatureSpan, atIndex: d)
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // encapsulate: now add ligature components to dmNode
        
        for (id, dmLigatureSpans) in dmLigatureSpansByID {
            for dmLigatureSpan in dmLigatureSpans {
                
                let startSystem = systems[dmLigatureSpan.systemStartIndex!]
                let stopIntValue = dmLigatureSpan.stopIntValue!
                let lastDMNode = startSystem.dmNodeByID[id]!
                let lastLigature = lastDMNode.ligatures.last!
                if lastLigature.finalDynamicMarkingIntValue == nil {
                    let x = startSystem.frame.width + 20
                    lastLigature.completeHalfOpenToX(x, withDynamicMarkingIntValue: stopIntValue)
                    lastLigature.position.y = 0.5 * lastDMNode.frame.height
                }
                
                let stopSystem = systems[dmLigatureSpan.systemStopIndex!]
                let startIntValue = dmLigatureSpan.startIntValue!
                let firstDMNode = stopSystem.dmNodeByID[id]!
                let firstLigature = firstDMNode.ligatures.first!
                if firstLigature.initialDynamicMarkingIntValue == nil {
                    firstLigature.completeHalfOpenFromLeftWithDynamicMarkingIntValue(startIntValue)
                    firstLigature.position.y = 0.5 * firstDMNode.frame.height
                }
                
                for s in dmLigatureSpan.systemStartIndex! + 1..<dmLigatureSpan.systemStopIndex! {
                    
                    if systems[s].dmNodeByID[id] == nil {
                        // create dmNode
                        let dmNode = DMNode(height: 2.5 * g) // hack
                        dmNode.startLigatureAtX(0, withDynamicMarkingIntValue: startIntValue)
                        dmNode.ligatures.last!.completeHalfOpenToX(systems[s].frame.width + 20,
                            withDynamicMarkingIntValue: stopIntValue
                        )
                        dmNode.ligatures.last!.position.y = 0.5 * dmNode.frame.height
                        
                        dmNode.build()
                        systems[s].dmNodeByID[id] = dmNode
                        
                        // hail mary
                        systems[s].eventsNode.insertNode(dmNode,
                            afterNode: systems[s].performerByID[id]!
                        )
                        
                        // dmNode.startLigature
                        // dmNode.completeHalfOpenToX
                    }
                }
            }
        }
    }
}