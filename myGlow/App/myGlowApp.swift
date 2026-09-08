//
//  myGlowApp.swift
//  myGlow
//
//  Created by Soraia Freire Batista on 31/08/26.
//

import SwiftData
import SwiftUI

@main
struct myGlowApp: App {
    private let container: ModelContainer
    @State private var ambiente: AppEnvironment
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        SoundManager.shared.playBackgroundMusic(isOn: true)
        Fontes.registrar()
        let container = Self.criarContainer()
        self.container = container
        _ambiente = State(initialValue: AppEnvironment(contexto: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(ambiente)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }

 
    private static func criarContainer() -> ModelContainer {
        let schema = Schema([MakeupItem.self, UserProgress.self, FotoSalva.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            assertionFailure("Falha ao abrir o store do SwiftData: \(error)")
            return try! ModelContainer(
                for: schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
    }
}
