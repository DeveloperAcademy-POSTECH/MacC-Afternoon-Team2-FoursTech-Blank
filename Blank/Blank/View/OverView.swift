//
//  OverView.swift
//  MacroView
//
//  Created by Greed on 10/14/23.
//

import SwiftUI

struct OverView: View {
    @Environment(\.dismiss) private var dismiss
    
    //뷰모델
    @ObservedObject var overViewModel: OverViewModel
    
    //향후 오버뷰 페이지로 돌아오기 위한 flag
    @State var isLinkActive = false
    
    //n회차 alert flag
    @State var showingAlert = false
    //n회차 일때 한번에 테스트 페이지로 가기 위한 bool값
    @State var goToTestPage = false
    
    //제목 버튼 팝오버 버튼
    @State private var showPopover = false
    @State private var showModal = false
    
    @State private var currentPageText: String = ""
    @State var titleName = "파일이름"
    
    var body: some View {
        NavigationStack {
            VStack {
                if overViewModel.isLoading && overViewModel.currentProgress < 1.0 {
                    progressStatus
                } else if !overViewModel.thumbnails.isEmpty {
                    pdfImage
                    bottomScrollView
                }
            }
            .onAppear {
                overViewModel.loadThumbnails()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leftBtns
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    testBtn
                }
                
                ToolbarItem(placement: .principal) {
                    centerBtn
                }
            }
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarBackButtonHidden()
            .navigationTitle(titleName)
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color(.systemGray6))
        .navigationDestination(isPresented: $isLinkActive) {
            if !goToTestPage {
                WordSelectView(overViewModel: overViewModel, isLinkActive: $isLinkActive)
            } else {
                TestPageView(overViewModel: overViewModel , isLinkActive: $isLinkActive)
            }
        }
    }
    
    private var progressStatus: some View {
        VStack(spacing: 20) {
            ProgressView(value: overViewModel.currentProgress)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("파일을 로딩 중 입니다.")
            
            Text("\(Int(overViewModel.currentProgress * 100))%") // 퍼센트로 변환하여 표시
        }
        .background(.white)
    }
    
    private var pdfImage: some View {
        VStack {
            Spacer().frame(height: 10)
            ScrollView(showsIndicators: false) {
                CurrentPageView(image: overViewModel.generateImage())
                    .frame(height: UIScreen.main.bounds.height * 0.8)
            }
        }
    }
    
    private var bottomScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Spacer().frame(height: 10)
            ScrollViewReader { proxy in
                LazyHStack(spacing: 10) {
                    ForEach(overViewModel.thumbnails.indices, id: \.self) { index in
                        VStack {
                            Image(uiImage: overViewModel.thumbnails[index])
                                .resizable()
                                .aspectRatio(contentMode:.fit)
                                .border(overViewModel.currentPage == index + 1 ? Color.blue : Color.clear, width: 1)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
                            Spacer().frame(height: 0)
                            Text("\(index+1)")
                                .font(.caption)
                        }
                        .onTapGesture {
                            overViewModel.currentPage = index + 1
                        }
                    }
                }
                .onChange(of: overViewModel.currentPage, perform: { value in
                    withAnimation {
                        proxy.scrollTo(value - 1, anchor: .center)
                    }
                })
                .onAppear() {
                    DispatchQueue.main.async {
                        proxy.scrollTo(overViewModel.currentPage - 1, anchor: .center)
                    }
                }
            }
        }
        .background(Color.white)
        .frame(height : UIScreen.main.bounds.height * 0.11)
    }
    
    private var centerBtn: some View {
        Button {
            showPopover = true
        } label: {
            HStack {
                Text("\(overViewModel.currentFile.fileName)")
                Image(systemName: "chevron.down")
            }
            .foregroundColor(.black)
            .fontWeight(.bold)
        }
        .popover(isPresented: $showPopover) {
            popoverContent
        }
    }
    
    private var popoverContent: some View {
        VStack {
            Form {
                // TODO: 파일 이름 변경가능?
//                TextField("\(overViewModel.currentFile.fileName)", text: $overViewModel.currentFile.fileName)
                Text("\(overViewModel.currentFile.fileName)")
                HStack {
                    Text("페이지 : ")
                    Spacer()
                    TextField("", text: $currentPageText, onCommit:{
                        overViewModel.updateCurrentPage(from: currentPageText)
                    })
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    Text(" / \(overViewModel.pdfTotalPage())")
                }
            }
        }
        .frame(width: 300, height: 150)
        .onAppear() {
            currentPageText = "\(overViewModel.currentPage)"
        }
    }
    
    private var leftBtns: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Button {
                showModal = true
            } label: {
                Image(systemName: "square.grid.2x2.fill")
            }
            .sheet(isPresented: $showModal) {
                OverViewModalView(overViewModel: overViewModel)
            }
            
            Menu {
                // TODO: 회차가 끝날때마다 해당 회차 결과 생성 및 시험 본 부분 색상 처리(버튼으로)
                Text("전체통계")
                Text("1회차")
                Text("2회차")
                Text("3회차")
                Text("4회차")
                
            } label: {
                Label("결과보기", systemImage: "chevron.down")
                    .labelStyle(.titleAndIcon)
            }
            
            Button {
                // TODO: 원본 페이지 상태로 변경
            } label: {
                Text("원본")
            }
        }
    }
    
    private var testBtn: some View {
        Button {
            // TODO: 해당 페이지 이미지 파일로 넘겨주기, layer 분리, 이미지 받아서 텍스트로 변환, 2회차 이상일때 내용수정 Alert 만들기
            isLinkActive = true
            // TODO: 2회차 이상일때 alert 띄울 로직
            //            showingAlert = true
        } label: {
            Text("시험준비")
                .fontWeight(.bold)
        }
        .alert("내용수정" ,isPresented: $showingAlert) {
            Button("시험보기") {
                goToTestPage = true
            }
            Button("수정하기") {
                
            }
            Button("취소", role: .cancel) {
                
            }
        } message: {
            Text("""
                 기존에 시험을 본 내용이 있습니다.
                 바로 시험을 보시겠습니까?
                 수정하시겠습니까?
                 """)
        }
        
    }
    
}

//#Preview {
//    OverView(viewModel: OverViewModel(currentFile: File))
//}
