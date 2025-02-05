import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var selectedNames: String
    @Environment(\.dismiss) private var dismiss
    
    private func formatContactName(_ contact: CNContact) -> String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }
    
    private func isContactAlreadyAdded(_ contact: CNContact) -> Bool {
        let existingNames = selectedNames.components(separatedBy: ", ")
        let newName = formatContactName(contact)
        return existingNames.contains(newName)
    }
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "NOT SELF IN %@", 
            selectedNames.components(separatedBy: ", "))
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
            let newContacts = contacts.filter { !parent.isContactAlreadyAdded($0) }
            
            if !newContacts.isEmpty {
                let names = newContacts.map { parent.formatContactName($0) }
                let newNames = names.joined(separator: ", ")
                
                // Append to existing companions if not empty
                if !parent.selectedNames.isEmpty {
                    parent.selectedNames += ", \(newNames)"
                } else {
                    parent.selectedNames = newNames
                }
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