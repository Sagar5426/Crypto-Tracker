//
//  Untitled.swift
//  CrytoTracker
//
//  Created by Sagar Jangra on 28/09/2025.
//


import SwiftUI


class ObservableViewModel: ObservableObject {
    @Published var title: String = "Some Title"
}

struct ObservableBootcamp: View {
    @StateObject private var vm  = ObservableViewModel()
    var body: some View {
        VStack {
            Button(vm.title) {
                vm.title = "New Title"
            }
            
            SomeChildView(vm: vm)
            ThirdChildView(vm: vm)
        }
    }
}

struct SomeChildView: View {
    @ObservedObject var vm : ObservableViewModel
    var body: some View {
        Button(vm.title) {
            vm.title = "Title 2"
        }
    }
}

struct ThirdChildView: View {
    @StateObject var vm :ObservableViewModel
    var body: some View {
        
        Button(vm.title) {
            vm.title = "Title 3"
        }
    }
}

#Preview {
    ObservableBootcamp()
}
