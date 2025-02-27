//
//  TagView.swift
//  VoiceNoteApp
//
//  Created by Ditmar Jubica on 1/28/25.
//
import SwiftUI

struct TagGridView: View {
    let tags: [Videos]
    let onselect: (Videos) -> Void
    
    // Define a flexible grid layout
    let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 20), count: 5) // 3 columns

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(tags, id: \.self) { tag in
                Text(tag.keyword ?? "")
                    .font(.system(size: 25, weight: .bold))
                    .frame(maxWidth: .infinity,minHeight: 100) // Equal width
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    .onTapGesture {
                        self.onselect(tag)
                    }
            }
        }
        .padding()
    }
}
