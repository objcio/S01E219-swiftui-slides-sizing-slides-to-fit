//
//  ContentView.swift
//  Slides
//
//  Created by Chris Eidhof on 11.08.20.
//  Copyright © 2020 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct Presentation<S: SlideList, Theme: ViewModifier>: View {
    var slides: S
    var theme: Theme
    @State var currentSlide = 0
    @State var numberOfSteps = 1
    @State var currentStep = 0
    
    init(@SlideBuilder slides: () -> S, theme: Theme) {
        self.slides = slides()
        self.theme = theme
    }
    
    init(slides: S, theme: Theme) {
        self.slides = slides
        self.theme = theme
    }
    
    func previous() {
        if currentSlide > 0  {
            currentSlide -= 1
            currentStep = 0
        }
    }
    
    func next() {
        if currentStep + 1 < numberOfSteps {
            withAnimation(.default) {
                currentStep += 1
            }
        } else if currentSlide + 1 < slides.count {
            currentSlide += 1
            currentStep = 0
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Previous") { self.previous() }
                Text("Slide \(currentSlide + 1) of \(slides.count) — Step \(currentStep + 1) of \(numberOfSteps)")
                Button("Next") { self.next() }
            }
            SlideContainer(content: slides.slide(at: currentSlide), theme: theme)
                .onPreferenceChange(StepsKey.self, perform: {
                    self.numberOfSteps = $0
                })
                .environment(\.currentStep, currentStep)
                .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                .border(Color.black)
        }
    }
}

extension Presentation where Theme == EmptyModifier {
    init(@SlideBuilder slides: () -> S) {
        self.init(slides: slides, theme: .identity)
    }
}

struct SlideContainer<Content: View, Theme: ViewModifier>: View {
    let size = CGSize(width: 1920, height: 1080)
    let content: Content
    let theme: Theme
    
    var body: some View {
        GeometryReader { proxy in
            self.content
                .frame(width: self.size.width, height: self.size.height)
                .modifier(self.theme)
                .scaleEffect(min(proxy.size.width/self.size.width, proxy.size.height/self.size.height))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}


struct MyTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .background(Color.blue)
            .font(.custom("Avenir", size: 48))
    
        
    }
}

struct StepsKey: PreferenceKey {
    static let defaultValue: Int = 1
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}

struct CurrentStepKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    var currentStep: Int {
        get { self[CurrentStepKey.self] }
        set { self[CurrentStepKey.self] = newValue }
    }
}

struct Slide<Content: View>: View {
    var steps: Int = 1
    let content: (Int) -> Content
    @Environment(\.currentStep) var step: Int
    
    var body: some View {
        content(step)
            .preference(key: StepsKey.self, value: steps)
    }
}

struct ImageSlide: View {
    var body: some View {
        Slide(steps: 2) { step in
            Image(systemName: "tortoise")
                .frame(maxWidth: .infinity, alignment: step > 0 ? .trailing :  .leading)
                .padding(50)
        }
            
    }
}

@SlideBuilder var slides: some SlideList {
    Text("Hello, World!")
    ImageSlide()
    Slide(steps: 2) { step in
        HStack {
            Text("Hello")
            if step > 0 {
                Text("World")
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        Presentation(slides: slides, theme: MyTheme())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0..<slides.count) { ix in
            SlideContainer(content: AnyView(slides.slide(at: ix)), theme: MyTheme())
                .previewLayout(.fixed(width: 320, height: 180))
            .previewDisplayName("Slide \(ix+1)")
        }
    }
}
