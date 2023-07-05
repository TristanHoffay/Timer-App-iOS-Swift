//
//  DetailView.swift
//  TimerSwift
//
//  Created by Tristan on 4/21/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct routeData : Decodable
{
    let destination_addresses:[String]
    let origin_addresses:[String]
    let rows:[row]
    let status:String
}
struct row :Decodable {
    let elements: [element]
}
struct element : Decodable
{
    let distance:distance
    let duration:duration
    let status:String
}
struct distance : Decodable {
    let text:String
    let value:Int
}
struct duration : Decodable {
    let text:String
    let value:Int
}

struct DetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var toAddRoute = false
    @State private var showAlert = false
    @State private var newFromLoc = String()
    @State private var newToLoc = String()
    @State private var newCoords = ((Double(), Double()), (Double(), Double()))
    @State private var coordsFound = false
    
    @State private var stdDev = Double()
    
    @ObservedObject var item:Item
    
    var body: some View {
        VStack{
            Section {
                HStack {
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Avg:")
                        Text("Min:")
                        Text("Max:")
                        Text("Std Dv:")
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(item.avgTime!)
                        Text(item.times != nil ?
                             DetailView.formatTime(inSeconds:item.times!.min()!) :
                        "N/A")
                        Text(
                            item.times != nil ?
                            DetailView.formatTime(inSeconds:item.times!.max()!) :
                        "N/A")
                        Text(
                            item.times != nil && item.times!.count > 2 ?
                            DetailView.formatTime(inSeconds: DetailView.getStdDv(input: item)) :
                        "N/A")
                    }
                    Spacer()
                }
            }
            
//            Text("Coords:" + String(item.fromLat))
//            Text(String(item.fromLong))
//            Text(String(item.toLat))
//            Text(String(item.toLong))
            if (item.travelTime != nil)
            {
                Text("Estimated Google Maps travel time:")
                    .padding(.top)
                Text(item.travelTime!)
            }
            
            Spacer()
            List {
                Section {
                    item.times != nil ?
                    (
                        ForEach(Array(item.times!.reversed().enumerated()), id: \.element) { index, time in
                            HStack {
                                Text(DetailView.formatTime(inSeconds:time))
                                Spacer()
                                Text(item.timesDates![index], formatter: itemFormatter).foregroundColor(Color(.secondaryLabel))
                            }
                        }.onDelete(perform: {IndexSet in item.times!.remove(atOffsets: IndexSet)})
                    ) :
                    nil
                } header: {
                    HStack {
                        Text("Time")
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Text("Record Date")
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            Spacer()
            Spacer()
        }.navigationBarTitleDisplayMode(.inline).navigationTitle(item.name!)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toAddRoute = true
                } label: {
                    Image(systemName: "point.topleft.down.curvedto.point.filled.bottomright.up")
                }
            }
        }.alert("Add Route Calculation", isPresented: $toAddRoute, actions: {
            TextField("Starting Location:", text: $newFromLoc)
            TextField("Ending Location:", text: $newToLoc)
            Button("Add Route",action: {
                if(newFromLoc.isEmpty || newToLoc.isEmpty) {
                    showAlert = true
                }
                else {
                    forwardGeocoding(fromAddr: newFromLoc, toAddr: newToLoc)
                }
            }).alert(isPresented: $showAlert) {
                Alert(title: Text("Missing Location"),
                message: Text("One or more required location has not been entered."))
            }
            Button("Cancel", role: .cancel,
                   action: {
                toAddRoute = false
            })
        }, message: {
            Text("Enter route start and end locations as addresses")
        })
        .onChange(of: coordsFound) { newval in
            do {
                if (coordsFound)
                {
                    item.fromLat = newCoords.0.0
                    item.fromLong = newCoords.0.1
                    item.toLat = newCoords.1.0
                    item.toLong = newCoords.1.1
                    getJsonData()
                }
                
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    private func getJsonData() {
        let urlAsString = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=" + String(item.fromLat) + "," + String(item.fromLong) + "&destinations=" + String(item.toLat) + "," + String(item.toLong) + "&mode=driving&key=AIzaSyA7Cf7l2FBQDHhAeyN8c8osoR2B2vTCdaw"
        print(urlAsString)
        
        let url = URL(string: urlAsString)!
        let urlSession = URLSession.shared
        
        let jsonQuery = urlSession.dataTask(with: url, completionHandler: { data, response, error -> Void in
            if (error != nil) {
                print(error!.localizedDescription)
            }
            var err: NSError?
            
            do {
                let decodedData = try JSONDecoder().decode(routeData.self, from: data!)
            
                item.travelTime = decodedData.rows[0].elements[0].duration.text
                do {
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                
            } catch {
                print("error: \(error)")
            }
        })
        jsonQuery.resume()
    }
    public static func formatTime(inSeconds: Double) -> String {
        let intSeconds = Int(inSeconds)
        let hours = intSeconds / 3600
        let minutes = (intSeconds % 3600) / 60
        let seconds = (intSeconds % 3600) % 60
        let format = (hours > 0) ? (String(hours) + "h" + String(minutes) + "m" + String(seconds) + "s") : ((minutes > 0) ? (String(minutes) + "m" + String(seconds) + "s") : (String(format: "%.2f", inSeconds) + "s"))
        return format
    }
    public static func getAvg(input: Item) -> Double {
        if (input.times != nil)
        {
            let sum = input.times!.reduce(0, +)
            return (sum / Double(input.times!.count))
        }
        return 0
    }
    public static func getStdDv(input: Item) -> Double {
        if (input.times != nil)
        {
            let avg = getAvg(input: input)
            let v = input.times!.reduce(0, { $0 + ($1-avg)*($1-avg) })
            return sqrt(v / Double(input.times!.count - 1))
        }
        return 0
    }

func forwardGeocoding(fromAddr: String, toAddr: String)
    {
        let geoCoder = CLGeocoder();
        let address1 = fromAddr
        let address2 = toAddr
        CLGeocoder().geocodeAddressString(address1, completionHandler:
                                            {
            (placemarks, error) in
            
            if error != nil {
                print("Geocode failed: \(error!.localizedDescription)")
            } else if placemarks!.count > 0 {
                let placemark = placemarks![0]
                let location = placemark.location
                let coords = location!.coordinate
                print(coords.latitude)
                print(coords.longitude)
                
                CLGeocoder().geocodeAddressString(address2, completionHandler:
                                                    {
                    (placemarks, error) in
                    
                    if error != nil {
                        print("Geocode failed: \(error!.localizedDescription)")
                    } else if placemarks!.count > 0 {
                        let placemark = placemarks![0]
                        let location = placemark.location
                        let coords2 = location!.coordinate
                        print(coords.latitude)
                        print(coords.longitude)
                        
                        DispatchQueue.main.async {
                            
                            newCoords.0.0 = coords.latitude
                            newCoords.0.1 = coords.longitude
                            newCoords.1.0 = coords2.latitude
                            newCoords.1.1 = coords2.longitude
                            coordsFound = true
                        }
                        
                    }
                })
                
            }
        })
        
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(item: Item()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
