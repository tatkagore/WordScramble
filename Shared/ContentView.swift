//
//  ContentView.swift
//  Shared
//
//  Created by Tatiana Simmer on 24/05/2022.
//

import SwiftUI

struct TextFieldClearButton: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            
            if !text.isEmpty {
                Button(
                    action: { self.text = "" },
                    label: {
                        Image(systemName: "delete.left")
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                    }
                )
            }
        }
    }
}


struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    let gradient = LinearGradient(colors: [Color.white,Color.purple],
                                  startPoint: .top, endPoint: .bottom)
    
    init() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        NavigationView {
            gradient
                .ignoresSafeArea()
                .overlay(
                    List {
                        Section {
                            TextField("Enter your word", text: $newWord)
                                .autocapitalization(.none)
                                .keyboardType(.alphabet)
                                .padding()
                                .modifier(TextFieldClearButton(text: $newWord))
                                                        .multilineTextAlignment(.leading)
                        }
                        Section {
                            ForEach(usedWords, id: \.self) { word in
                                HStack {
                                    Image(systemName: "\(word.count).circle")
                                    Text(word)
                                }
                            }
                        }
                    }
                        .listStyle(InsetGroupedListStyle())
                        .onSubmit(addNewWord)
                        .onAppear(perform: startGame)
                        .alert(errorTitle, isPresented: $showingError) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text(errorMessage)
                        }
                        .toolbar {
                            ToolbarItem (placement: .navigationBarLeading){
                                VStack {
                                    Spacer()
                                        .frame(height: 50)
                                    HStack {
                                        Text(rootWord).font(.largeTitle).bold()
                                        Spacer()
                                        Button("New word") {
                                            self.startGame()
                                            usedWords.removeAll()
                                        }
                                    }
                                    HStack {
                                        Spacer()
                                            .frame(width: 20)
                                        Text("Create new words out of this word ✏️ ")
                                        Spacer()
                                            .frame(width: 20)
                                    }
                                    
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                )
        }
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard answer.count > 0 else { return }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        newWord = ""
    }
    func startGame() {
        // 1. Find the URL for start.txt in our app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // 2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // 3. Split the string up into an array of strings, splitting on line breaks
                let allWords = startWords.components(separatedBy: "\n")
                // 4. Pick one random word, or use "silkworm" as a sensible default
                rootWord = allWords.randomElement() ?? "silkworm"
                // If we are here everything has worked, so we can exit
                return
            }
        }
        // If were are *here* then there was a problem – trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    func isReal(word: String) -> Bool {
        if word.count < 3 || word == rootWord {
            return false
        } else {
            let checker = UITextChecker()
            let range = NSRange(location: 0, length: word.utf16.count)
            let misspeledWords = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
            return misspeledWords.location == NSNotFound
        }
    }
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
