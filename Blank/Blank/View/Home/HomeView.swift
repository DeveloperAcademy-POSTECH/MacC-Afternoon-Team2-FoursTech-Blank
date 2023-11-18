//
//  ContentView.swift
//  MacroView
//
//  Created by Greed on 10/14/23.
//

import SwiftUI

struct HomeView: View {
    enum Mode {
        case normal, edit
        
        var toggle: Mode {
            self == .edit ? .normal : .edit
        }
    }
    
    // 현재 일반 모드인지, 아니면 편집(=> 파일삭제) 모드인지
    @State var mode: Mode = .normal
    
    // UI 표시 토글 상태변수
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var showPDFCreateAlert = false
    @State private var showFileDeleteAlert = false
    @State private var isPopToHomeActive = false
    @State private var showCreateNewFolder = false
    @State private var showMoveFiles = false

    @StateObject var homeViewModel: HomeViewModel = .init()
    
    // 새 PDF 생성 관련
    @State var newPDFFileName = ""
    @State var targetImages: [UIImage]?
    @State var isAllowedCreateNewPDF = false
    
    // 새 폴더 생성 관련
    @State private var newFolderName = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                thumbGridView
            }
            .searchable(
                text: $homeViewModel.searchText,
                placement: .navigationBarDrawer,
                prompt: "Search"
            )
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    editBtn
                }
                
                ToolbarItem {
                    if mode == .normal {
                        fileBtnNormalMode
                    } else {
                        fileBtnEditMode
                    }
                }
            }
            .toolbarBackground(.blue.opacity(0.2), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("문서")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .navigationBarBackButtonHidden(true)
            // 시트뷰 설정
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerReperesentedView { url in
                    homeViewModel.addFileToDocument(from: url)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                // showPDFCreateAlert 1: 이미지 선택 창을 띄우고 끝나면 경고창 띄움
                // TODO: - 인디케이터 로딩 시작
                
                PhotoPickerRepresentedView { images in
                    // TODO: - 인디케이터 로딩 끝
                    print("이미지 결합 Phase 1 시작")
                    targetImages = images
                    setAllowCreateNewPDF(true)
                    showPDFCreateAlert = true
                }
            }
            // 파일 이동 뷰
            .sheet(isPresented: $showMoveFiles) {
                SelectFolderView()
            }
            .onChange(of: showPDFCreateAlert) {
                if $0 {
                    print("이미지 결합 Phase 1 끝")
                }
            }
            // Alert 설정: PDF 생성
            .alert("PDF 생성", isPresented: $showPDFCreateAlert) {
                let suggestedFileName = homeViewModel.suggestedFileName
                
                TextField(
                    "",
                    text: $newPDFFileName,
                    prompt: Text(suggestedFileName)
                )
                Button("Cancel") {
                    setAllowCreateNewPDF(false)
                }
                Button("OK") {
                    guard let targetImages else {
                        return
                    }
                    
                    // showPDFCreateAlert 2: OK를 누르면 다음 단계 진행
                    if newPDFFileName.isEmpty {
                        newPDFFileName = suggestedFileName
                    }
                    
                    print("이미지 결합 Phase 2 시작")
                    addImageCombinedPDFToDocument(from: targetImages)
                }
            } message: {
                Text("선택된 이미지들이 병합되어 PDF로 생성됩니다. 파일 이름을 확장자를 제외하고 입력해주세요.")
            }
            // Alert 설정: 선택한 파일 삭제
            .alert("선택한 파일 및 폴더 삭제", isPresented: $showFileDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    
                }
                Button("OK", role: .destructive) {
                    homeViewModel.removeSelectedFiles()
                    // 삭제 완료하면 일반 모드로 이동
                    mode = .normal
                }
            } message: {
                Text("정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
                + Text(!homeViewModel.selectedFolderList.isEmpty ? " 폴더를 삭제하는 경우 폴더 안의 모든 파일이 삭제됩니다." : "")
            }
            // Alert 설정: 새 폴더 만들기
            .alert("새로운 폴더의 이름을 입력하세요.", isPresented: $showCreateNewFolder) {
                TextField("", text: $newFolderName, prompt: .init("새 폴더"))
                Button("Cancel", role: .cancel) {
                    
                }
                Button("OK", role: .destructive) {
                    if newFolderName.isEmpty {
                        return
                    }
                    
                    homeViewModel.createNewDirectory(name: newFolderName)
                    newFolderName = ""
                    // 새 폴더 생성 완료하면 일반 모드로 이동
                    mode = .normal
                }
            } message: {
                Text("현재 위치에 새로운 폴더를 생성합니다.")
            }
        }
    }
    
    private var thumbGridView: some View {
        let item = GridItem(.adaptive(minimum: 225, maximum: 225), spacing: 30)
        let columns = Array(repeating: item, count: 3)
        
        return ScrollView {
            LazyVGrid(columns: columns) {
                if !homeViewModel.isLocatedInRootDirectory {
                    VStack {
                        FolderThumbnailView(isRoot: true)
                    }
                    .onTapGesture {
                        homeViewModel.fetchFileListFromParentDirectory()
                    }
                }
                
                ForEach(homeViewModel.filteredFileList, id: \.id) { fileComponent in
                    if let file = fileComponent as? File {
                        pdfThumbnail(file)
                    } else if let folder = fileComponent as? Folder {
                        folderThumbnail(folder)
                    }
                    
                }
            }
        }
        .refreshable {
            homeViewModel.fetchDocumentFileList()
        }
    }
    
    /// PDF 섬네일
    @ViewBuilder private func pdfThumbnail(_ file: File) -> some View {
        NavigationLink(
            destination: mode == .normal
                       ? OverView(overViewModel: OverViewModel(currentFile: file))
                       : nil
        ) {
            ZStack(alignment:.topTrailing) {
                PDFThumbnailView(file: file)
                
                if mode == .edit {
                    checkbox(file)
                }
            }
        }
        .foregroundColor(.black)
        .disabled(mode == .edit)
        .onTapGesture {
            if mode == .edit {
                updateSelection(file)
            }
        }
    }
    
    @ViewBuilder private func folderThumbnail(_ folder: Folder) -> some View {
        ZStack(alignment: .topTrailing) {
            FolderThumbnailView(folder: folder)
            
            if mode == .edit {
                checkbox(folder)
            }
        }
        .onTapGesture {
            if mode == .normal {
                homeViewModel.fetchDocumentFileList(folder.fileName)
            } else if mode == .edit {
                updateSelection(folder)
            }
        }
    }
    
    
    @ViewBuilder private func checkbox<T: FileSystem>(_ component: T) -> some View {
        let isContain: Bool = {
            if let component = component as? File {
                return homeViewModel.selectedFileList.contains(component)
            } else if let component = component as? Folder {
                return homeViewModel.selectedFolderList.contains(component)
            }
            
            return false
        }()
        
        Image(isContain ? "checkedCheckmark" : "emptyCheckmark")
            .offset(x: -20, y: 10)
    }
    
    private var fileBtnNormalMode: some View {
        Menu {
            Button {
                showFilePicker = true
            } label: {
                Text("파일 보관함")
            }
            Button {
                showImagePicker = true
            } label: {
                Text("사진 보관함")
            }
        } label: {
            // Text("새 파일")
            Text("파일 가져오기")
        }
    }
    
    private var fileBtnEditMode: some View {
        HStack {
            Button("이동") {
                showMoveFiles.toggle()
            }
            Button("새 폴더") {
                showCreateNewFolder.toggle()
            }
            
            Button {
                showFileDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var editBtn: some View {
        Button {
            mode = mode.toggle
            if mode == .normal {
                homeViewModel.selectedFileList = []
            }
        } label: {
            Text(mode == .normal ? "편집" : "취소")
        }
    }
}

extension HomeView {
    private func addImageCombinedPDFToDocument(from images: [UIImage]) {
        guard images.count > 0 && isAllowedCreateNewPDF else {
            return
        }
        
        do {
            let pdfData = createPDFFromUIImages(from: images)
            guard let targetDirectory = homeViewModel.currentDirectoryURL ?? FileManager.documentDirectoryURL else {
                setAllowCreateNewPDF(false)
                return
            }

            try pdfData.write(to: targetDirectory.appendingPathComponent("\(newPDFFileName).pdf"))
            homeViewModel.fetchDocumentFileList()
            
            setAllowCreateNewPDF(false)
            print("이미지 결합 Phase 2 끝")
        } catch {
            print("write pdf error:", error)
            setAllowCreateNewPDF(false)
        }
    }
    
    private func setAllowCreateNewPDF(_ isAllow: Bool) {
        isAllowedCreateNewPDF = isAllow
        newPDFFileName = ""
    }
    
    private func updateSelection(_ file: File) {
        if !homeViewModel.selectedFileList.contains(file) {
            homeViewModel.selectedFileList.insert(file)
        } else {
            homeViewModel.selectedFileList.remove(file)
        }
    }
    
    private func updateSelection(_ folder: Folder) {
        if !homeViewModel.selectedFolderList.contains(folder) {
            homeViewModel.selectedFolderList.insert(folder)
        } else {
            homeViewModel.selectedFolderList.remove(folder)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(HomeViewModel())
}

