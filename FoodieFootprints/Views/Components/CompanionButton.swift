import SwiftUI
import ContactsUI

struct CompanionButton: View {
    let name: String
    @State private var contact: CNContact?
    @State private var isContactLoaded = false
    
    var body: some View {
        Group {
            if isContactLoaded && contact != nil {
                Button(action: {
                    openContact(contact: contact!)
                }) {
                    Text(name)
                        .foregroundStyle(.blue)
                }
            } else {
                Text(name)
            }
        }
        .font(.subheadline)
        .task {
            contact = await name.findContact()
            isContactLoaded = true
        }
    }
    
    private func openContact(contact: CNContact) {
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = false
        contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { _ in
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.dismiss(animated: true)
                }
            }
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            let navController = UINavigationController(rootViewController: contactVC)
            rootVC.present(navController, animated: true)
        }
    }
}

private extension String {
    func findContact() async -> CNContact? {
        return await Task.detached {
            let store = CNContactStore()
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactViewController.descriptorForRequiredKeys() as CNKeyDescriptor
            ]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            var matchingContact: CNContact?
            try? store.enumerateContacts(with: request) { contact, _ in
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                if self == fullName {
                    matchingContact = contact
                }
            }
            return matchingContact
        }.value
    }
} 