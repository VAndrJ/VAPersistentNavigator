//
//  ExampleSafariView.swift
//  Example
//
//  Created by VAndrJ on 4/16/25.
//

import SafariServices
import SwiftUI

struct ExampleSafariView: View {
    let url: URL

    var body: some View {
        SFSafariRepresentableView(url: url)
    }

    private struct SFSafariRepresentableView: UIViewControllerRepresentable {
        let url: URL

        func makeUIViewController(context: Context) -> SFSafariViewController {
            return SFSafariViewController(url: url)
        }

        func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    }
}
