import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var selectedNames: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(value: true)
        picker.predicateForSelectionOfContact = NSPredicate(value: true)
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let names = contacts.map { "\($0.givenName) \($0.familyName)".trimmingCharacters(in: .whitespaces) }
            let newNames = names.joined(separator: ", ")
            
            // Append to existing companions if not empty
            if !parent.selectedNames.isEmpty {
                parent.selectedNames += ", \(newNames)"
            } else {
                parent.selectedNames = newNames
            }
            
            // Only dismiss the contact picker itself
            picker.dismiss(animated: true)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // Only dismiss the contact picker itself
            picker.dismiss(animated: true)
        }
    }
} 