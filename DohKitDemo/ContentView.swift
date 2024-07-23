//
//  ContentView.swift
//  DohKitDemo
//
//  Created by Zaid Tayyab on 17/01/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button (){
                Task {
                    do {
                      //  DispatchQueue.main.async {
                            
                        let dohManager = DOHManager(servers: ["1.1.1.1",
                                                              "1.0.0.1",
                                                              "2606:4700:4700::1111",
                                                              "2606:4700:4700::1001",], serverUrl: "https://cloudflare-dns.com/dns-query")
                        
                        await dohManager.startDoH()
                } catch {
                    print ("Error is \(error)")
                }
                
            }
            
            
        } label: {
            Text("Turn DoH")
        }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
