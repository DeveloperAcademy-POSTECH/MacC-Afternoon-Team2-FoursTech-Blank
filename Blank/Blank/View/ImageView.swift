//
//  ImageView.swift
//  Blank
//
//  Created by 조용현 on 10/19/23.
//

import SwiftUI
import Vision

struct ImageView: View {
    //경섭추가코드
    var uiImage: UIImage?
    @Binding var visionStart:Bool
    @State private var recognizedBoxes: [(String, CGRect)] = []
    
    //경섭추가코드
    var viewName: String?
    
    //for drag gesture
    @State var startLocation: CGPoint?
    @State var endLocation: CGPoint?
    
    @Binding var isSelectArea: Bool
    
    // 다른 뷰에서도 사용할 수 있기 때문에 뷰모델로 전달하지 않고 개별 배열로 전달해봄
    @Binding var basicWords: [BasicWord]
    @Binding var targetWords: [Word]
    @Binding var currentWritingWords: [Word]
    
    @State var isAreaTouched: [Int: Bool] = [:]
    
    let cornerRadiusSize: CGFloat = 5
    let fontSizeRatio: CGFloat = 1.9
    
    @State var zoomScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { proxy in
            // ScrollView를 통해 PinchZoom시 좌우상하 이동
            Image(uiImage: uiImage ?? UIImage())  //경섭추가코드를 받기위한 변경
                .resizable()
                .scaledToFit()
            
            // GeometryReader를 통해 화면크기에 맞게 이미지 사이즈 조정
            
            //                이미지가 없다면 , 현재 뷰의 너비(GeometryReader의 너비)를 사용하고
            //                더 작은 값을 반환할건데
            //                이미지 > GeometryReader 일 때 이미지는 GeometryReader의 크기에 맞게 축소.
            //                반대로 GeometryReader > 이미지면  이미지의 원래 크기를 사용
                .frame(
                    width: max(uiImage?.size.width ?? proxy.size.width, proxy.size.width) ,
                    height: max(uiImage?.size.height ?? proxy.size.height, proxy.size.height)
                )
                .onChange(of: visionStart, perform: { newValue in
                    if let image = uiImage {
                        
                        recognizeText(from: image) { recognizedTexts  in
                            self.recognizedBoxes = recognizedTexts
                            basicWords = recognizedTexts.map { .init(id: UUID(), wordValue: $0.0, rect: $0.1, isSelectedWord: false) }
                        }
    
                    }
                })
            // 조조 코드 아래 일단 냅두고 위의 방식으로 수정했음
                .overlay {
                    // TODO: Image 위에 올릴 컴포넌트(핀치줌 시 크기고정을 위해 width, height, x, y에 scale갑 곱하기)
                    
                    if viewName == "WordSelectView" {
                        
                        if let start = startLocation, let end = endLocation {
                            Rectangle()
                                .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                                .frame(width: abs(end.x - start.x), height: abs(end.y - start.y))
                                .position(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
                        }
                        ForEach(basicWords.indices, id: \.self) { index in
                            Rectangle()
                                .path(in: adjustRect(basicWords[index].rect, in: proxy))
                                .fill( basicWords[index].isSelectedWord  ? Color.green.opacity(0.4) : Color.white.opacity(0.01))
                                .onTapGesture {
                                    withAnimation {
                                        basicWords[index].isSelectedWord = isSelectArea ? true : false
                                    }
                                }
                        }
                        
                        
                        
                    } else if viewName == "ResultPageView" {
                        // TargetWords의 wordValue에는 원래 값 + 맞고 틀림 여부(isCorrect)이 넘어온다
                        ForEach(targetWords.indices, id: \.self) { index in
                            let adjustRect = adjustRect(targetWords[index].rect, in: proxy)
                            let isCorrect = targetWords[index].isCorrect
                            let originalValue = targetWords[index].wordValue
                            let wroteValue = currentWritingWords[index].wordValue
                            
                            
                            RoundedRectangle(cornerSize: .init(width: cornerRadiusSize, height: cornerRadiusSize))
                                .path(in: adjustRect)
                                .fill(isCorrect ? Color.correctColor.shadow(.inner(color: .clear,radius: 0, y: 0)) : isAreaTouched[index, default: false] ? Color.flippedAreaColor.shadow(.inner(color: .black.opacity(0.5),radius: 2, y: -1)) : Color.wrongColor.shadow(.inner(color: .black.opacity(0.5),radius: 2, y: -1)))
                                .shadow(color: isCorrect ? .clear : .black.opacity(0.7), radius: 0, x: 1, y: 2)
                                .overlay(
                                    Text("\(isCorrect ? originalValue : isAreaTouched[index, default: false] ? originalValue : wroteValue)")
                                        .font(.system(size: adjustRect.height / fontSizeRatio, weight: .semibold))
                                        .offset(
                                            x: -(proxy.size.width / 2) + adjustRect.origin.x + (adjustRect.size.width / 2),
                                            y: -(proxy.size.height / 2) + adjustRect.origin.y + (adjustRect.size.height / 2)
                                        )
                                )
                                .onTapGesture {
                                    // 기존 탭제스쳐 방식
                                    if !targetWords[index].isCorrect {
                                        isAreaTouched[index, default: false].toggle()
                                    }
                                }
                        }
                    }
                }
            
                .gesture(
                    DragGesture()
                        .onChanged{ value in
                            if startLocation == nil {
                                startLocation = value.location
                            }
                            
                            endLocation = value.location
                            
                            // 드래그 경로에 있는 단어 선택 1. rect구하기
                            let dragRect = CGRect(x: min(startLocation!.x, endLocation!.x),
                                                  y: min(startLocation!.y, endLocation!.y),
                                                  width: abs(endLocation!.x - startLocation!.x),
                                                  height: abs(endLocation!.y - startLocation!.y))
                            
                            for index in basicWords.indices {
                                if dragRect.intersects(adjustRect(basicWords[index].rect, in: proxy)) {
                                    basicWords[index].isSelectedWord = isSelectArea ? true : false
                                }
                            }
                        }
                        .onEnded{ value in
                            // drag 끝나면 초기화
                            startLocation = nil
                            endLocation = nil
                        }
                )
        }
    }
    
    
    // ---------- Mark : 반자동   ----------------
    func adjustRect(_ rect: CGRect, in geometry: GeometryProxy) -> CGRect {
        
        let imageSize = self.uiImage?.size ?? CGSize(width: 1, height: 1)
        
        // Image 뷰 너비와 UIImage 너비 사이의 비율
        let scaleY: CGFloat = geometry.size.height / imageSize.height
        
        // 기기별 사이즈
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        
        var deviceX: CGFloat = 0.0
        
        switch (screenHeight ,screenWidth) {
        case (1366, 1024):
            // iPad Pro 12.9인치 모델 (1세대부터 6세대까지)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 6.5 )  + (rect.origin.x * scaleY))
        case (1194, 834):
            // iPad Pro 11인치 모델 (1세대부터 4세대까지)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 7.0 )  + (rect.origin.x * scaleY))
        case (1112, 834):
            // iPad Pro 10.5인치, iPad Air (3세대)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 4.5 )  + (rect.origin.x * scaleY))
        case (1080, 810):
            // iPad (7세대), iPad (8세대), iPad (9세대)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 4.0 )  + (rect.origin.x * scaleY))
        case (1180, 820):
            // iPad Air (4세대), iPad Air (5세대), iPad (10세대)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 7.0 )  + (rect.origin.x * scaleY))
        case (1024, 768):
            // iPad Pro 9.7인치, iPad (5세대), iPad (6세대), iPad mini (5세대)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 3.43 )  + (rect.origin.x * scaleY))
        case (1133, 744):
            // iPad mini (6세대)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 15.0 )  + (rect.origin.x * scaleY))
        default:
            // 알 수 없는 또는 다른 해상도를 가진 모델 (12.9인치 모델을 deafult로 함)
            deviceX = ( ( (geometry.size.width - imageSize.width) / 6.5 )  + (rect.origin.x * scaleY))
        }
        
        return CGRect(
            x: deviceX,
            y:( imageSize.height - rect.origin.y - rect.size.height) * scaleY ,
            width: rect.width * scaleY ,
            height : rect.height * scaleY
        )
    }
    
    
    
    
}

//
//#Preview {
//    ImageView(scale: .constant(1.0))
//}
