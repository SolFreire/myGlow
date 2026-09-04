//
//  ImageView.swift
//  myGlow
//
//  Created by marquiros on 03/09/26.
//

import SwiftUI
import AVFoundation

struct ImageView: View {
    var image: Image?
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            }
        }
    }
}
