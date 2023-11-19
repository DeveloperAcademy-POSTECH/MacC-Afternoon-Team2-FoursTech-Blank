//
//  OverVIewImageView.swift
//  Blank
//
//  Created by Sup on 10/24/23.
//

import SwiftUI
import Vision

struct OverViewImageView: View {
    //경섭추가코드
    @Binding var visionStart: Bool
    
    @StateObject var overViewModel: OverViewModel
    //경섭추가코드
    @State var zoomScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { proxy in
            ZoomableContainer(zoomScale: $zoomScale) {
                // ScrollView를 통해 PinchZoom시 좌우상하 이동
                Image(uiImage: overViewModel.currentImage ?? UIImage())  //경섭추가코드를 받기위한 변경
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: max(overViewModel.currentImage?.size.width ?? proxy.size.width, proxy.size.width),
                        height: max(overViewModel.currentImage?.size.height ?? proxy.size.height, proxy.size.height)
                    )
                
                // 통계가 나타나는 부분
                    .overlay {
                        // TODO: Image 위에 올릴 컴포넌트(핀치줌 시 크기고정을 위해 width, height, x, y에 scale갑 곱하기)
                        if overViewModel.isTotalStatsViewMode {
                            ZStack {
                                ForEach(Array(overViewModel.totalStats.keys), id: \.self) { key in
                                    if let stat = overViewModel.totalStats[key] {
                                        Rectangle()
                                            .path(in: adjustRect(key, in: proxy))
                                            .fill(stat.isAllCorrect ? Color.green.opacity(0.4) : Color.red.opacity(0.4))
                                            .onTapGesture {
                                                overViewModel.totalStats[key]?.isSelected = true
                                            }
                                    }
                                }
                                // 전체통계 뷰 뜨게 하는 기능
                               // ForEach(Array(overViewModel.totalStats.keys), id: \.self) { key in
                               //     if let stat = overViewModel.totalStats[key] {
                               //         Image("PopoverShape")
                               //             .resizable()
                               //             .shadow(radius: 1)
                               //             .opacity(0.7)
                               //             .frame(width: proxy.size.width / 15 / zoomScale, height: proxy.size.height / 20 / zoomScale)
                               //             .overlay{
                               //                 VStack(spacing: -2 * zoomScale) {
                               //                     Group {
                               //                         Text("\(stat.correctSessionCount)/\(stat.totalSessionCount)")
                               //                             .font(.system(size: proxy.size.height / 40 / zoomScale))
                               //                         Text("(\(stat.correctRate.percentageTextValue(decimalPlaces: 0)))")
                               //                             .font(.system(size: proxy.size.height / 50 / zoomScale))
                               //                     }
                               //                     .scaleEffect(0.8 / zoomScale)
                               //                 }
                               //             }
                               //             .position(x: adjustRect(key, in: proxy).midX, y: adjustRect(key, in: proxy).origin.y + 45 - zoomScale * 5)
                               //     }
                               // }
                            }
                        } else if let currentSession = overViewModel.currentSession,
                                  let words = overViewModel.wordsOfSession[currentSession.id] {
                            ForEach(words, id: \.id) { word in
                                Rectangle()
                                    .path(in: adjustRect(word.rect, in: proxy))
                                    .fill(word.isCorrect ? Color.green.opacity(0.4) : Color.red.opacity(0.4))
                            }
                        }
                        
                    }
            }
        }
    }
    
    // ---------- Mark : 기존 반자동 코드   ----------------
//    func adjustRect(_ rect: CGRect, in geometry: GeometryProxy) -> CGRect {
//        
//        let imageSize = overViewModel.currentImage?.size ?? CGSize(width: 1, height: 1)
//        
//        // Image 뷰 너비와 UIImage 너비 사이의 비율
//        let scaleY: CGFloat = geometry.size.height / imageSize.height
//        
//        
//        return CGRect(
//            x: ( ( (geometry.size.width - imageSize.width) / 3.5 )  + (rect.origin.x * scaleY))   *  zoomScale   ,
//            
//            // 좌우반전
//            //                x:  (imageSize.width - rect.origin.x - rect.size.width) * scaleX * scale ,
//            
//            y:( imageSize.height - rect.origin.y - rect.size.height) * scaleY * zoomScale ,
//            width: rect.width * scaleY * zoomScale,
//            height : rect.height * scaleY * zoomScale
//        )
//    }
    
    // ---------- Mark : 반자동   ----------------
    func adjustRect(_ rect: CGRect, in geometry: GeometryProxy) -> CGRect {
        
        let imageSize = overViewModel.currentImage?.size ?? CGSize(width: 1, height: 1)
        
        // Image 뷰 너비와 UIImage 너비 사이의 비율
        let scaleY: CGFloat = geometry.size.height / imageSize.height
        let deviceModel = UIDevice.current.name
        var deviceX: CGFloat = 0.0
        
        switch deviceModel {
        case "iPad Pro (12.9-inch) (6th generation)":
            deviceX = ( ( (geometry.size.width - imageSize.width) / 3.5 )  + (rect.origin.x * scaleY)) * zoomScale
        case "iPad Pro (11-inch) (4th generation)":
            deviceX = ( ( (geometry.size.width - imageSize.width) / 3.0 )  + (rect.origin.x * scaleY)) * zoomScale
        case "iPad (10th generation)":
            deviceX = ( ( (geometry.size.width - imageSize.width) / 2.9 )  + (rect.origin.x * scaleY)) * zoomScale
        case "iPad Air (5th generation)":
            deviceX = ( ( (geometry.size.width - imageSize.width) / 2.9 )  + (rect.origin.x * scaleY)) * zoomScale
        case "iPad mini (6th generation)":
            deviceX = ( ( (geometry.size.width - imageSize.width) / 2.8 )  + (rect.origin.x * scaleY)) * zoomScale
        default:
            deviceX = ( ( (geometry.size.width - imageSize.width) / 3.5 )  + (rect.origin.x * scaleY)) * zoomScale
        }
        
        
        return CGRect(
            x: deviceX  ,
            y:( imageSize.height - rect.origin.y - rect.size.height) * scaleY * zoomScale ,
            width: rect.width * scaleY * zoomScale ,
            height : rect.height * scaleY * zoomScale
        )
    }
    
    
    
}

//
//#Preview {
//    ImageView(scale: .constant(1.0))
//}
