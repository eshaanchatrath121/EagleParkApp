//
//  LoginView.swift
//  EaglePark
//
//  Created by Eshaan Chatrath on 11/27/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    enum Field {
        case email, password
    }
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var buttonDisabled = true
    @State private var presentSheet = false
    @FocusState private var focusField: Field?
    
    @State private var allowedDomains: [String] = []
    
    struct SchoolResponse: Codable {
        let schools: [School]
    }
    struct School: Codable {
        let name: String
        let email_domain: String
    }
    
    var body: some View {
        ZStack {
            
            Color(red: 0.45, green: 0, blue: 0.07)
                .ignoresSafeArea()
            
            VStack {
                Text("Eagle Park")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(Color(red: 0.87, green: 0.72, blue: 0.22))
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                    .padding(.bottom, 8)
                
                Spacer()
                
                Image("icon")
                    .resizable()
                    .scaledToFit()
                
                Spacer()
                
                Group {
                    TextField("email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                        .focused($focusField, equals: .email)
                        .onSubmit {
                            focusField = .password
                        }
                        .onChange(of: email) {
                            enableButtons()
                        }
                    
                    SecureField("password", text: $password)
                        .submitLabel(.done)
                        .focused($focusField, equals: .password)
                        .onSubmit {
                            focusField = nil
                        }
                        .onChange(of: password) {
                            enableButtons()
                        }
                }
                .textFieldStyle(.roundedBorder)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.gray.opacity(0.5), lineWidth: 2)
                }
                
                HStack {
                    Button("Sign Up") {
                        register()
                    }
                    .padding(.leading)
                    
                    Button("Log In") {
                        login()
                    }
                    .padding(.trailing)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.87, green: 0.72, blue: 0.22))
                .foregroundStyle(.black)
                .font(.title2)
                .padding(.top)
                .disabled(buttonDisabled)
                
                Spacer()
                
                Text("Stop Circling. Start Soaring.")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(Color(red: 0.87, green: 0.72, blue: 0.22))
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                    .padding(.bottom, 8)
            }
            .padding()
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            .onAppear {
                if Auth.auth().currentUser != nil {
                    presentSheet = true
                }
                
                Task {
                    await loadSchoolDomains()
                }
            }
            .fullScreenCover(isPresented: $presentSheet) {
                EagleParkHomeView()
            }
        }
    }
        
    func enableButtons() {
        let emailIsGood = email.count >= 6 && email.contains("@")
        let passwordIsGood = password.count >= 6
        buttonDisabled = !(emailIsGood && passwordIsGood)
    }
    
    func validateEmailAgainstJSON() -> Bool {
        guard let domain = email.split(separator: "@").last else { return false }
        return allowedDomains.contains(String(domain))
    }
    
    func loadSchoolDomains() async {
        guard let url = URL(string: "https://mocki.io/v1/3199de02-043f-42e9-ab7a-d59977c7c3ef") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(SchoolResponse.self, from: data)
            allowedDomains = decoded.schools.map { $0.email_domain }
            print("📡 Loaded domains:", allowedDomains)
        } catch {
            print("❌ Error loading domains:", error.localizedDescription)
        }
    }
    
    func register() {
        guard validateEmailAgainstJSON() else {
            alertMessage = "❌ Please use a valid school email."
            showingAlert = true
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "😡 SIGNUP ERROR: \(error.localizedDescription)"
                showingAlert = true
            } else {
                print("😎 Registration success!")
                presentSheet = true
            }
        }
    }
    
    func login() {
        guard validateEmailAgainstJSON() else {
            alertMessage = "❌ Please use a valid school email."
            showingAlert = true
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = "😡 LOGIN ERROR: \(error.localizedDescription)"
                showingAlert = true
            } else {
                print("🪵 Login success!")
                presentSheet = true
            }
        }
    }
}

#Preview {
    LoginView()
}
