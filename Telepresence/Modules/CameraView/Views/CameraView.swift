//
//  CameraView.swift
//  VideoToGif
//
//  Created by Muhammad Junaid Babar on 2/24/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject var cameraViewModel = CameraViewModel()
    @State var isRecording = false
    
    var body: some View {
        ZStack {
            if let image = cameraViewModel.filteredImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 400) // Adjust as needed
            } else {
                Text("Loading...")
                    .foregroundColor(.gray)
            }

           
            
        }
        .onAppear {
            
        }
        .onDisappear {
            
        }
        
        
        
        
    }
   
    
}

#Preview {
    CameraView()
}
