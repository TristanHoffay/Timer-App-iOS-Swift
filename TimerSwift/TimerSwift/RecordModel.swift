//
//  RecordModel.swift
//  TimerSwift
//
//  Created by Tristan on 4/21/23.
//

import Foundation

struct Record: Identifiable {
    var id = UUID()
    var name = String()
    var usesGeo: Bool = false
    var fromLoc: (Double, Double)
    var toLoc: (Double, Double)
    var times: [Double] = []
}
