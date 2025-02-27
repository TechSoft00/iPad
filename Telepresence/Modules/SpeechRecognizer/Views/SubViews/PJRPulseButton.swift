//
//  PJRPulseButton.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/3/25.
//

import SwiftUI

struct PJRPulseButton: View {
    
    // MARK: - Properties
    @Binding var isAnimating: Bool
    var color: Color
    var systemImageName: String
    var buttonWidth: CGFloat
    var numberOfOuterCircles: Int
    var animationDuration: Double
    var circleArray = [CircleData]()

    init(isAnimating: Binding<Bool>, color: Color = Color.blue, systemImageName: String = "plus.circle.fill", buttonWidth: CGFloat = 48, numberOfOuterCircles: Int = 2, animationDuration: Double = 1) {
        self._isAnimating = isAnimating
        self.color = color
        self.systemImageName = systemImageName
        self.buttonWidth = buttonWidth
        self.numberOfOuterCircles = numberOfOuterCircles
        self.animationDuration = animationDuration
        
        var circleWidth = self.buttonWidth
        var opacity = (numberOfOuterCircles > 4) ? 0.40 : 0.20
        
        for _ in 0..<numberOfOuterCircles {
            circleWidth += 20
            self.circleArray.append(CircleData(width: circleWidth, opacity: opacity))
            opacity -= 0.05
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            ForEach(circleArray, id: \.self) { circle in
                Circle()
                    .fill(self.color)
                    .opacity(isAnimating ? circle.opacity : 0)
                    .frame(width: circle.width, height: circle.width)
                    .scaleEffect(isAnimating ? 1 : 0)
                    .animation(
                        isAnimating
                            ? Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)
                            : .default, // Default animation when stopping
                        value: isAnimating
                    )
            }

            Button(action: {
                isAnimating.toggle()
                print("Button Pressed, isAnimating: \(isAnimating)")
            }) {
                Image(systemName: self.systemImageName)
                    .resizable()
                    .scaledToFit()
                    .background(Circle().fill(Color.white))
                    .frame(width: self.buttonWidth, height: self.buttonWidth)
                    .accentColor(color)
            }
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    isAnimating.toggle()
                    isAnimating.toggle()
                }
            }
        }
    }
}

// MARK: - Preview
struct PulseButton_Previews: PreviewProvider {
    static var previews: some View {
        PJRPulseButton(isAnimating: .constant(true))
    }
}

// MARK: - CircleData Struct
struct CircleData: Hashable {
    let width: CGFloat
    let opacity: Double
}
