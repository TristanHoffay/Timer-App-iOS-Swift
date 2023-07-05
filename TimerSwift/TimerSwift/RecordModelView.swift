//
//  RecordModelView.swift
//  TimerSwift
//
//  Created by Tristan on 4/21/23.
//

import Foundation

public class cityViewModel:ObservableObject
{
    @Published var data = [City(name: "Phoenix", description: "Hottest place in the solar system", image: "phoenix"),
                           City(name: "Seattle", description: "Home of the citizens of Seattle", image: "seattle"),
                           City(name: "Denver", description: "IDK I haven't been there", image: "denver"),
                           City(name: "Albany", description: "They have an airport", image: "albany"),
                           City(name: "Tempe", description: "There's a state university here I think...", image: "tempe")]
    
}
