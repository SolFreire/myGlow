//
//  CameraPreview.swift
//  myGlow
//

import SwiftUI
import UIKit

struct CameraPreview: View {
    @Environment(CameraModel.self) var model: CameraModel
    @Environment(\.voltarAoSalao) private var voltarAoSalao
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                Color(.fundoCamera).ignoresSafeArea(edges: .all)
                HStack  {
                    Spacer()
                    ImageView(image: model.previewImage)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .frame(maxWidth: width * 0.45, maxHeight: height * 0.9)
                    Spacer()
                    buttonsView(largura: width, altura: height)
                    Spacer()
                }
                if let countdown = model.countdown {
                    Text("\(countdown)")
                        .font(.system(size: 100, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 10)
                }
            }
        }
        .onAppear {
            OrientationManager.shared.updateOrientation(to: .landscapeRight, forceRotateTo: .landscapeRight)
        }
        .onDisappear{
            OrientationManager.shared.updateOrientation(to: .landscape)
        }
        .navigationBarBackButtonHidden(true)
        
        .toolbar {
            ToolbarItem(placement: .topBarLeading){
                Button {
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    voltarAoSalao()
                } label: {
                    Image(systemName: "door.right.hand.open")
                        .font(Font.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: nil)
                .background(Paleta.botaoDeCamera.gradiente, in: Capsule())
            }
            .sharedBackgroundVisibility(.hidden)
            
            ToolbarItem (placement: .title) {
                Text("GlowShot")
                    .font(Tipografia.secao)
                    .foregroundStyle(Color.corBotaoCamera)
                    .bold()
            }
            
            ToolbarItem (placement: .topBarTrailing) {
                BotaoPrimario(titulo: model.timerLabel, simbolo: "timer", cores: Paleta.botaoDeCamera, preencheLargura: false){
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    model.changeCameraTimer()
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
        
    }
    
    
    private func buttonsView(largura: CGFloat, altura: CGFloat) -> some View {
        HStack (spacing: 0) {
            //BOTÕES DE ZOOM (0.5, 1 e 2)
            VStack(spacing: 50) {
                Button("0.5x") {
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    model.selectZoom(0.5)
                }
                .foregroundStyle(.corBotaoCamera)
                .fontWeight(.semibold)
                .overlay {
                    if model.selectedZoom == 0.5 {
                        Text("0.5x")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .frame(minWidth: 50, minHeight: 50)
                            .background(Paleta.botaoDeCamera.gradiente, in: Capsule())
                            .clipShape(Circle())
                    }
                }
                Button("1x") {                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    model.selectZoom(1)
                }
                .foregroundStyle(.corBotaoCamera)
                .fontWeight(.semibold)
                .toggleStyle(.button)
                .overlay {
                    if model.selectedZoom == 1 {
                        Text("1x")
                            .font(Tipografia.botao)
                            .frame(minWidth: 50, minHeight: 50)
                            .background(Paleta.botaoDeCamera.gradiente, in: Capsule())
                            .clipShape(Circle())
                    }
                }
                
                Button("2x") {
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    model.selectZoom(2)
                }
                .foregroundStyle(.corBotaoCamera)
                .fontWeight(.semibold)
                .overlay {
                    if model.selectedZoom == 2 {
                        Text("2x")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .frame(minWidth: 50, minHeight: 50)
                            .background(Paleta.botaoDeCamera.gradiente, in: Capsule())
                            .clipShape(Circle())
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(.bottom, 24)
            
            Spacer()
            //BOTÕES DE TIRAR FOTO, FLASH e SWITCH
            VStack {
                Spacer()
                //TIRAR FOTO
                Button {
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    model.startCameraTimer()
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(.corBotaoCameraClaro), location: 0.23),
                                    Gradient.Stop(color: Color(.corBotaoCamera), location: 0.95),
                                ],
                                startPoint: UnitPoint(x: 0.5, y: 0),
                                endPoint: UnitPoint(x: 0.5, y: 1)
                            )
                            )
                            .stroke(LinearGradient(stops: [
                                Gradient.Stop(color: Color(.corBotaoCameraClaro), location: 0.23),
                                Gradient.Stop(color: Color(.corBotaoCamera), location: 0.95),
                            ], startPoint: UnitPoint(x: -1.5, y: -4), endPoint: UnitPoint(x: 0, y: 1)),
                                    lineWidth: 7)
                            .frame(width: largura * 0.19, height: altura * 0.4)
                    }
                }
                Spacer()
                //FLASH e SWITCH
                HStack (spacing: 30) {
                    //FLASH
                    BotaoPrimario(simbolo: model.flashModeIcon, tamanho: .camera, cores: Paleta.botaoDeCamera, preencheLargura: false){
                        SoundManager.shared.playSoundEffect(named: "botao-efeito")
                        model.toggleFlash()
                    }
                    //SWITCH
                    Button {
                        SoundManager.shared.playSoundEffect( named: "botao-efeito")
                        model.switchCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(Font.system(size: 30, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .frame(maxWidth: nil)
                    .background(Paleta.botaoDeCamera.gradiente, in: Capsule())
                }
                
            }
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.white)
        }
        .frame(maxWidth: largura * 0.35, maxHeight: altura * 0.9)
        .padding(.horizontal)
    }
    
}

#Preview {
    @Previewable @State var model = CameraModel()
    CameraPreview()
        .environment(model)
}

