//
//  PromptView.swift
//  Telepresence
//
//  Created by Muhammad Junaid Babar on 2/14/25.
//


import SwiftUI

struct PromptView: View {
    @State private var showPrompt = true
    @State private var countdown = 5
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            if showPrompt {
                VStack(spacing: 20) {
                    Text("Are you still there?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text("\(countdown)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.red)
                        .animation(.easeInOut, value: countdown)
                    
                    HStack {
                        Button(action: {
                            dismissPrompt()
                        }) {
                            Text("YES")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 60)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        
                        Button(action: resetPrompt) {
                            Text("Reset")
                                .font(.title2)
                                .foregroundColor(.black)
                                .frame(width: 150, height: 60)
                                .background(Color.gray)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .frame(width: 500, height: 300)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                
            }
        }
        .onAppear(perform: startCountdown)
    }
    
    private func startCountdown() {
        countdown = 5
        showPrompt = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                dismissPrompt()
            }
        }
    }
    
    private func dismissPrompt() {
        timer?.invalidate()
        showPrompt = false
    }
    
    private func resetPrompt() {
        dismissPrompt()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startCountdown()
        }
    }
}

struct PromptView_Previews: PreviewProvider {
    static var previews: some View {
        PromptView()
    }
}
