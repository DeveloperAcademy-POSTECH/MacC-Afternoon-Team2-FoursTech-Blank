//
//  TextView.swift
//  Blank
//
//  Created by 조용현 on 10/23/23.
//

import SwiftUI

struct TextView: View {
    @State var name: String = ""
    @Binding var height: CGFloat
    @Binding var width: CGFloat
    @State var isFocused: Bool = false
    @Binding var scale: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            UITextViewRepresentable(text: $name, isFocused: $isFocused, height: $height, scale: $scale)
                .frame(width: width, height: height)
        }
        .border(isFocused ? Color.yellow : Color.green, width: 1.5)
    }
}


struct UITextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var height: CGFloat
    @Binding var scale: CGFloat
    var fontSize: CGFloat = 1.5

    func makeUIView(context: UIViewRepresentableContext<UITextViewRepresentable>) -> UITextView {
        let textView = UITextView(frame: .zero)
        textView.delegate = context.coordinator
        textView.font = UIFont(name: "Avenir", size: (height/fontSize) * scale)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.textContainer.maximumNumberOfLines = 2
        return textView
    }

    func makeCoordinator() -> UITextViewRepresentable.Coordinator {
        Coordinator(text: self.$text, isFocused: self.$isFocused)
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<UITextViewRepresentable>) {

        uiView.text = self.text
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        @Binding var isFocused: Bool

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            self._text = text
            self._isFocused = isFocused
        }


        func textViewDidChangeSelection(_ textView: UITextView) {
            self.text = textView.text ?? ""
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            self.isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            self.isFocused = false
        }

    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let existingLines = textView.text.components(separatedBy: CharacterSet.newlines)
        let newLines = text.components(separatedBy: CharacterSet.newlines)
        let linesAfterChange = existingLines.count + newLines.count - 1
        if(text == "\n") {
            return linesAfterChange <= textView.textContainer.maximumNumberOfLines
        }

        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 30
    }
}


#Preview {
    TextView(name: "안녕하세요", height: .constant(30), width: .constant(100), isFocused: false, scale: .constant(1.0))
}