import SwiftUI
import UIKit

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup { GameView() }
    }
}

struct Floater: Identifiable {
    let id = UUID()
    let text: String
    let dx: CGFloat
}

struct FloatingText: View {
    let floater: Floater
    @State private var rise = false

    var body: some View {
        Text(floater.text)
            .font(.title2.bold())
            .foregroundStyle(.yellow)
            .offset(x: floater.dx, y: rise ? -150 : -50)
            .opacity(rise ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.8)) { rise = true } }
            .allowsHitTesting(false)
    }
}

struct GameView: View {
    @AppStorage("coins") private var coins: Double = 0
    @AppStorage("power") private var power: Int = 1
    @AppStorage("autos") private var autos: Int = 0
    @State private var pop = false
    @State private var floaters: [Floater] = []

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var powerCost: Int { Int(10 * pow(1.5, Double(power - 1))) }
    private var autoCost: Int { Int(50 * pow(1.6, Double(autos))) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("🪙 \(Int(coins))")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("+\(power) per tap  ·  \(autos) per second")
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                ZStack {
                    Button(action: tap) {
                        Text("🪙")
                            .font(.system(size: 110))
                            .frame(width: 230, height: 230)
                            .background(Circle().fill(.white.opacity(0.2)))
                            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 4))
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(pop ? 0.92 : 1)

                    ForEach(floaters) { FloatingText(floater: $0) }
                }

                Spacer()

                upgradeRow(title: "Stronger Tap",
                           subtitle: "+1 coin per tap",
                           cost: powerCost) { power += 1 }
                upgradeRow(title: "Auto Clicker",
                           subtitle: "+1 coin every second",
                           cost: autoCost) { autos += 1 }
            }
            .padding()
        }
        .onReceive(timer) { _ in
            if autos > 0 { coins += Double(autos) }
        }
    }

    private func tap() {
        coins += Double(power)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.15)) { pop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.15)) { pop = false }
        }

        let f = Floater(text: "+\(power)", dx: CGFloat.random(in: -60...60))
        floaters.append(f)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            floaters.removeAll { $0.id == f.id }
        }
    }

    private func upgradeRow(title: String, subtitle: String, cost: Int,
                            action: @escaping () -> Void) -> some View {
        let affordable = coins >= Double(cost)
        return Button {
            guard affordable else { return }
            coins -= Double(cost)
            action()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(title).bold()
                    Text(subtitle).font(.caption)
                }
                Spacer()
                Text("🪙 \(cost)").bold()
            }
            .foregroundStyle(.black)
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(affordable ? 0.95 : 0.35)))
        }
        .disabled(!affordable)
    }
}
