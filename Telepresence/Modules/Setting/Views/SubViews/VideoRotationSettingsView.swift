//
//  VideoRotationSettingsView.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/20/25.
//

import SwiftUI

struct VideoRotationSettingsView: View {
    @Binding var selectedRotation: Int
    let rotationOptions = [90, 180, 270, 360]
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            HStack( spacing: 15) {
                Text("Video Orientation Setting")
                    .font(.headline)
                Spacer()
                Picker("Rotation", selection: $selectedRotation) {
                    ForEach(rotationOptions, id: \.self) { angle in
                        Text("\(angle)°").tag(angle)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .frame(maxWidth: 400)
                
                
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 3)
        .onAppear {
            selectedRotation = UserDefaults.standard.integer(forKey: "videoRotation")
        }
    }
}

#Preview {
    //VideoRotationSettingsView()
}
