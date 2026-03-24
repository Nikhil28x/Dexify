//
//  DinosaurView.swift
//  Dexify
//
//  Created by Nikhil Dsouza  on 16/06/25.
//


import SwiftUI

struct DinosaurView: View {
    @State private var jump = false

    var body: some View {
        Image(uiImage:#imageLiteral(resourceName: "dino4.png") ) // Your dinosaur asset name in Assets.xcassets
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .offset(y: jump ? -10 : 0)
            .animation(
                Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: jump
            )
            .onAppear {
                jump = true
            }
    }
}
