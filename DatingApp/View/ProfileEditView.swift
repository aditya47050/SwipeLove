import SwiftUI
import PhotosUI
import FirebaseFirestore

struct ProfileEditView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var displayName: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Profile Image Preview
                Group {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let userImage = base64ToImage(authVM.appUser?.profileImageData) {
                        Image(uiImage: userImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(authVM.appUser?.displayName.prefix(1) ?? "U")
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 140, height: 140)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                // Display Name Input
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .disableAutocorrection(true)
                    .autocapitalization(.words)

                // Image Picker
                PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Select Profile Image")
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.pink.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .onChange(of: photoPickerItem) { newItem in
                    loadImage(from: newItem)
                }

                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .scaleEffect(1.5)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Save Button
                Button(action: saveProfile) {
                    Text("Save")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving
                                    ? Color.gray.opacity(0.5)
                                    : Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                }
                .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
            .padding(.vertical, 20)
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                displayName = authVM.appUser?.displayName ?? ""
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationViewStyle(.stack)
    }

    func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data, let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                case .failure(let error):
                    print("Failed to load image: \(error.localizedDescription)")
                }
            }
        }
    }

    func saveProfile() {
        guard let uid = authVM.authUser?.uid else { return }
        isSaving = true
        errorMessage = nil

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Display Name cannot be empty."
            isSaving = false
            return
        }

        let userRef = Firestore.firestore().collection("users").document(uid)

        // Update displayName first
        userRef.updateData(["displayName": trimmedName]) { error in
            if let error = error {
                self.errorMessage = "Failed to update name: \(error.localizedDescription)"
                self.isSaving = false
                return
            }

            // Update profileImageData if new image selected
            if let image = selectedImage,
               let imageData = image.jpegData(compressionQuality: 0.7) {
                let base64String = imageData.base64EncodedString()
                authVM.updateProfileImageData(base64String: base64String) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Failed to update image: \(error.localizedDescription)"
                            self.isSaving = false
                        } else {
                            self.isSaving = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
