//
//  SettingView.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/4/25.
//

import SwiftUI
import PhotosUI
import AVKit

import SwiftUI

struct SettingView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = SettingViewModel()
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @State private var showValidationError: Bool = false
    var onDataSaved: () -> Void = {} // Callback when data is saved
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    settingsList()
                }
                .padding()
                
                InitialVideoSettingView()
                    .padding()
               
                VideoRotationSettingsView(selectedRotation: $viewModel.selectedRotation)
                    .padding()
                
                FaceDetectionVideoSettingView(isSettingOn: $viewModel.faceDetectionVideoSetting, faceDetectionVideo: $viewModel.faceDetectionVideo)
                    .padding()
                
                actionButtons()
            }
            .padding()
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(leading: closeButton())
            .alert("Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    // MARK: - Settings List
    private func settingsList() -> some View {
        ForEach(0..<viewModel.settingItems.count, id: \.self) { index in
            SettingItemView(settingItem: $viewModel.settingItems[index]) {
                viewModel.deleteVideo(at: index)
                self.onDataSaved()
            }
        }
    }
    
    // MARK: - Action Buttons
    private func actionButtons() -> some View {
        HStack {
            saveButton()
            addButton()
        }
        .padding()
    }
    
    // MARK: - Save Button
    private func saveButton() -> some View {
        Button {
            if viewModel.isAllFieldsValid() {
                Task {
                    viewModel.saveAllData()
                    onDataSaved()
                    presentationMode.wrappedValue.dismiss() // Close the view
                }
            } else {
                showValidationError = true
            }
        } label: {
            Text("Save")
                .padding(15)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 2)
        }
    }
    
    // MARK: - Add More Button
    private func addButton() -> some View {
        Button(action: {
            viewModel.addNewItem()
        }) {
            Text("Add More")
                .padding(15)
                .frame(width: 200)
                .background(Color.blue)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 2)
        }
    }
    
    // MARK: - Close Button (Navigation Bar)
    private func closeButton() -> some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss() // Close the view
        }) {
            Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.black)
        }
    }
}
