import SwiftUI
import UIKit

struct KitchenTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Palette.placeholder))
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocapitalization)
            .foregroundColor(Palette.ink)
            .tint(Palette.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Palette.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Palette.primary.opacity(0.28), lineWidth: 1)
            )
    }
}

struct KitchenNoteEditor: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Palette.placeholder)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
            }
            TextEditor(text: $text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Palette.ink)
                .scrollContentBackground(.hidden)
                .tint(Palette.primary)
                .frame(minHeight: 96)
                .padding(8)
        }
        .background(Palette.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Palette.primary.opacity(0.28), lineWidth: 1)
        )
    }
}
