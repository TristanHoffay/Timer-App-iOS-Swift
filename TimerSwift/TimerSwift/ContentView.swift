//
//  ContentView.swift
//  TimerSwift
//
//  Created by Tristan on 4/21/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State var showAddTask = false
    @State private var recordName = String()
    @State private var selection = 0
    @State private var pickIndex:Int = 0
    @State private var timerRunning = false
    @State var startTime = Date.now
    @State var timeElapsed: Double = 0.0
    
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection: $selection) {
            
            // Home Page
            VStack{
                Spacer()
                Text("Task Selection:")
                    .multilineTextAlignment(.center)
                Picker(selection: $pickIndex, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/) {
                    ForEach(items.indices) { index in
                        Text(items[index].name!)
                    }
                    .onDelete(perform: deleteItems)
                }.pickerStyle(.wheel)
                Button("Create New Task") {
                    showAddTask = true
                }
                Spacer()
                if (items.count > 0)
                {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Avg:")
                            Text("Min:")
                            Text("Max:")
                            Text("Std Dv:")
                        }
                        Spacer()
                        updateStats(index: pickIndex)
                        Spacer()
                    }
                }
                else {
                    Text("No Available Records")
                }
                // est route time
                Spacer()
                if (timerRunning) {
                    Section {
                        Text("Timer Running")
                            .foregroundColor(Color(.secondaryLabel))
                        Text(String(format: "%.2f", timeElapsed)).onReceive(timer) { firedDate in
                            timeElapsed = Double(firedDate.timeIntervalSince(startTime))
                        }
                        Button() {
                            if (items[pickIndex].times == nil) {
                                items[pickIndex].times = [Double]()
                            }
                            items[pickIndex].times!.append(timeElapsed)
                            if (items[pickIndex].timesDates == nil) {
                                items[pickIndex].timesDates = [Date]()
                            }
                            items[pickIndex].timesDates!.append(Date.now)
                            items[pickIndex].avgTime = DetailView.formatTime(inSeconds: DetailView.getAvg(input: items[pickIndex]))
                            timerRunning = false
                            do {
                                try viewContext.save()
                            } catch {
                                // Replace this implementation with code to handle the error appropriately.
                                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                            }
                        } label: {
                            Label("Stop and Save to Task", systemImage: "timer").foregroundColor(Color.red)
                        }
                    }
                }
                else {
                    VStack {
                        if (items.count > 0)
                        {
                            Text("Timer Not Running")
                                .foregroundColor(Color(.secondaryLabel))
                            Button() {
                                startTime = Date.now
                                timerRunning = true
                            } label: {
                                Label("Start Timer", systemImage: "timer").foregroundColor(Color.green)
                            }
                        }
                    }
                }
                Spacer()
            }.tabItem { Label("Home", systemImage: "house") }.tag(1)
            
            // Record page
            NavigationView {
                List {
                    Section {
                        ForEach(items) { item in
                            NavigationLink {
                                DetailView(item: item)
                            } label: {
                                HStack {
                                    Text(item.name!)
                                    Spacer()
                                    Text(
                                        
                                        item.avgTime!
                                        
                                    ).foregroundColor(Color(.secondaryLabel))
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } header: {
                        HStack {
                            Text("Task")
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Text("avg time")
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }.navigationBarTitleDisplayMode(.inline).navigationTitle("Records")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showAddTask = true
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                
            }.tabItem { Label("Records", systemImage: "list.number.rtl") }.tag(2)
        }.alert("Create New Record", isPresented: $showAddTask, actions: {
            TextField("Name:", text: $recordName)
            Button("Create",action: {
                addItem(name: recordName)
            })
            Button("Cancel", role: .cancel,
                   action: {
                showAddTask = false
            })
        }, message: {
            Text("Enter info for a new record to collect times under")
        })
    }
    private func updateStats(index:Int) -> VStack<TupleView<(Text, Text, Text, Text)>> {
        return VStack(alignment: .trailing) {
            Text(items[index].avgTime!)
            Text(items[index].times != nil ?
                 DetailView.formatTime(inSeconds:items[index].times!.min()!) :
                    "N/A")
            Text(
                items[index].times != nil ?
                DetailView.formatTime(inSeconds:items[index].times!.max()!) :
                    "N/A")
            Text(
                items[index].times != nil && items[index].times!.count > 2 ?
                DetailView.formatTime(inSeconds:DetailView.getStdDv(input: items[index])) :
                    "N/A")
        }
    }
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    private func addItem(name:String) {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.name = name
            newItem.timestamp = Date()
            newItem.avgTime = "N/A"

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
