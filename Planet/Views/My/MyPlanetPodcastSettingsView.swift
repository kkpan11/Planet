//
//  MyPlanetPodcastSettingsView.swift
//  Planet
//
//  Created by Xin Liu on 10/7/22.
//

import SwiftUI

struct MyPlanetPodcastSettingsView: View {
    let CONTROL_CAPTION_WIDTH: CGFloat = 80
    let CONTROL_ROW_SPACING: CGFloat = 8

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var planetStore: PlanetStore
    @ObservedObject var planet: MyPlanetModel
    @State private var name: String

    @State private var podcastLanguage: String = "en"
    @State private var podcastExplicit: Bool = false

    let categories: [String: [String]] = PodcastUtils.categories
    @State private var selectedCategories: [String: Bool] = [:]

    init(planet: MyPlanetModel) {
        self.planet = planet
        _name = State(wrappedValue: planet.name)

        _podcastLanguage = State(wrappedValue: planet.podcastLanguage ?? "en")
        _podcastExplicit = State(wrappedValue: planet.podcastExplicit ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {

                HStack(spacing: 10) {

                    if let image = planet.avatar {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24, alignment: .center)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("BorderColor"), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    else {
                        Text(planet.nameInitials)
                            .font(Font.custom("Arial Rounded MT Bold", size: 12))
                            .foregroundColor(Color.white)
                            .contentShape(Rectangle())
                            .frame(width: 24, height: 24, alignment: .center)
                            .background(
                                LinearGradient(
                                    gradient: ViewUtils.getPresetGradient(from: planet.id),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("BorderColor"), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }

                    Text("\(planet.name)")
                        .font(.body)

                    Spacer()
                }

                TabView {
                    VStack(spacing: CONTROL_ROW_SPACING) {
                        HStack {
                            HStack {
                                Text("Language")
                                Spacer()
                            }
                            .frame(width: CONTROL_CAPTION_WIDTH)

                            TextField("", text: $podcastLanguage)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            HStack {
                                Spacer()
                            }.frame(width: CONTROL_CAPTION_WIDTH + 10)
                            Toggle(
                                "Podcast contains explicit contents",
                                isOn: $podcastExplicit
                            )
                            .toggleStyle(.checkbox)
                            .frame(alignment: .leading)
                            Spacer()
                        }
                    }
                    .padding(16)
                    .tabItem {
                        Text("General")
                    }

                    VStack(spacing: CONTROL_ROW_SPACING) {
                        LazyVGrid(columns: [GridItem(), GridItem()], alignment: .leading) {
                            ForEach(Array(categories.keys), id: \.self) { category in
                                HStack {
                                    Toggle(
                                        category,
                                        isOn: binding(for: category)
                                    )
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(16)
                    .tabItem {
                        Text("Categories")
                    }
                }

                HStack(spacing: 8) {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(width: 50)
                    }
                    .keyboardShortcut(.escape, modifiers: [])

                    Button {
                        planet.podcastLanguage = podcastLanguage
                        planet.podcastExplicit = podcastExplicit
                        Task {
                            try planet.save()
                            try planet.copyTemplateAssets()
                            try planet.articles.forEach { try $0.savePublic() }
                            try planet.savePublic()
                            NotificationCenter.default.post(name: .loadArticle, object: nil)
                            try await planet.publish()
                        }
                        dismiss()
                    } label: {
                        Text("OK")
                            .frame(width: 50)
                    }
                    .disabled(name.isEmpty)
                }

            }.padding(20)
        }
        .padding(0)
        .frame(width: 520, height: 460, alignment: .top)
        .task {
            name = planet.name
        }
    }

    private func binding(for category: String) -> Binding<Bool> {
        return Binding(get: {
            return self.selectedCategories[category] ?? false
        }, set: {
            self.selectedCategories[category] = $0
        })
    }
}
