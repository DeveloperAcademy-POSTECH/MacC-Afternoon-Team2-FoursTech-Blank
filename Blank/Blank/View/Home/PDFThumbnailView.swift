//
//  PdfThumbnailCardView.swift
//  MacroView
//
//  Created by Greed on 10/14/23.
//

import SwiftUI

struct PDFThumbnailView: View {
    @State var file: File
    @State var thumbnail = Image("thumbnail")
    
    var body: some View {
        VStack {
            thumbnail
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
                .frame(height: 140)
            Spacer().frame(height: 15)
            Text("\((URL(fileURLWithPath: file.fileName).deletingPathExtension().lastPathComponent))")
                .font(.headline)
                .fontWeight(.bold)
//            Text("전체 페이지수: \(file.totalPageCount)")
            Text("Total Page Count: \(file.totalPageCount)")
//                .font(.footnote)
                .font(.system(size: 11))
//            Text("시험 본 페이지: \(file.solvedPageCount)")
            Text("Count of Pages Tested: \(file.solvedPageCount)")
//                .font(.footnote)
                .font(.system(size: 11))
            Spacer()
        }
        .padding()
        .onAppear {
            prepareThumbnail(from: file.fileURL)
        }
    }
}

extension PDFThumbnailView {
    private func prepareThumbnail(from url: URL) {
        guard let thumbnail = generateThumbnail(of: .init(width: 120, height: 150), for: url, atPage: 0) else {
            return
        }
        
        self.thumbnail = Image(uiImage: thumbnail)
    }
}

#Preview {
    HomeView()
}
