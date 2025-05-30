import SwiftUI

/// A view modifier that adds a red asterisk to any view to indicate a required field
struct RequiredFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack(spacing: 0) {
            content
            Text("*").foregroundColor(.red)
        }
    }
}

/// A reusable header view for form sections that need to indicate a required field
struct RequiredSectionHeader: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(text)
            Text("*").foregroundColor(.red)
        }
    }
}

/// A reusable picker view with a required field indicator
struct RequiredPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Picker(selection: $selection) {
            content()
        } label: {
            HStack(spacing: 0) {
                Text(title)
                Text("*").foregroundColor(.red)
            }
        }
        .pickerStyle(.menu)
    }
}

// Extension to make the modifier more convenient to use
extension View {
    /// Adds a red asterisk to the view to indicate that it's a required field
    func required() -> some View {
        modifier(RequiredFieldModifier())
    }
} 