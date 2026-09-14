//
//  SubstituicoesCuradas.swift
//  myGlow
//

import Foundation


nonisolated enum SubstituicoesCuradas {
    struct Regra: Sendable {
        let substituto: String
        let comoFazer: String
    }

    struct Par: Sendable {
        let ausente: String
        let regra: Regra
    }

    /// Só alimenta o prompt da IA (`FoundationModelsSuggester.prompt`), que já
    /// escolhe entre o template PT e o EN pelo mesmo idioma resolvido pelo
    /// bundle — este valor precisa acompanhar a mesma escolha.
    private static var emIngles: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("en") ?? false
    }

    static func regiao(da categoria: CategoriaItem) -> String {
        switch categoria {
        case .batom, .gloss, .lapisLabial:
            emIngles ? "mouth" : "boca"
        case .sombra, .delineadorLiquido, .lapisOlho, .lapisOlhoBranco, .mascara, .sobrancelha, .ciliosPosticos:
            emIngles ? "eyes" : "olhos"
        case .base, .corretivo, .po, .blush, .contorno, .iluminador, .clown, .pancake:
            emIngles ? "face" : "rosto"
        }
    }


    static func fatoTecnico(da categoria: CategoriaItem) -> String {
        switch categoria {
        case .base:
            String(localized: "Base é cobertura uniforme no tom da própria pele, aplicada no rosto todo — sem variante de cor.")
        case .corretivo:
            String(localized: "Corretivo cobre olheiras e manchas pontuais, no tom da pele ou um pouco mais claro — sem variante de cor.")
        case .po:
            String(localized: "Pó fixa a maquiagem e corta o brilho — translúcido ou no tom da pele, nunca colorido.")
        case .blush:
            String(localized: "Blush dá cor às maçãs do rosto pode ir na boca nem nos olhos.")
        case .contorno:
            String(localized: "Contorno é sempre num tom terroso/acastanhado, pra esculpir sombra — nunca colorido.")
        case .iluminador:
            String(localized: "Iluminador ilumina os pontos altos do rosto (maçãs, nariz, arco do cupido) — não é pigmento de cor.")
        case .sombra:
            String(localized: "Sombra é pálpebra — cada cor já é um produto do catálogo, nunca invente uma cor que não foi citada.")
        case .delineadorLiquido:
            String(localized: "Delineador líquido traça uma linha fina e definida rente aos cílios.")
        case .lapisOlho:
            String(localized: "Lápis de olho tem ponta macia — serve pra traços mais suaves ou esfumados que a caneta líquida.")
        case .lapisOlhoBranco:
            String(localized: "Lápis branco ilumina o canto interno do olho ou a linha d'água.")
        case .mascara:
            String(localized: "Máscara dá volume e curvatura aos próprios cílios.")
        case .sobrancelha:
            String(localized: "Produto de sobrancelha preenche falhas e define o formato — só na sobrancelha.")
        case .batom:
            String(localized: "Batom cobre o lábio inteiro, de forma opaca.")
        case .gloss:
            String(localized: "Gloss dá brilho e volume ao lábio, cobertura mais leve que o batom.")
        case .lapisLabial:
            String(localized: "Lápis labial contorna e preenche o lábio, geralmente por baixo do batom.")
        case .clown:
            String(localized: "Tinta clown é uma base branca opaca, pra contraste teatral no rosto todo.")
        case .pancake:
            String(localized: "Pancake sela a maquiagem numa camada fosca, por cima de outro produto de base.")
        case .ciliosPosticos:
            String(localized: "Cílios postiços vão colados sobre a linha dos cílios naturais, pra volume extra.")
        }
    }

    static func aplicaveis(faltantes: [String], idsNaMaleta: Set<String>) -> [Par] {
        faltantes.compactMap { ausente in
            guard let regra = regras[ausente]?.first(where: { idsNaMaleta.contains($0.substituto) })
            else { return nil }
            return Par(ausente: ausente, regra: regra)
        }
    }

    static let semSubstituto = String(localized: "Não achei um substituto razoável com o que você possui, vamos seguindo com a maquiagem.")

    static let regras: [String: [Regra]] = [
        "caneta-delineadora": [
            Regra(
                substituto: "lapis-preto",
                comoFazer: String(localized: "Aqueça a ponta do lápis por alguns segundos entre os dedos, trace a linha rente aos cílios em pequenos tracinhos e depois una tudo num traço só. Para o efeito de caneta, passe por cima de novo pressionando mais firme.")
            ),
            Regra(
                substituto: "sombra-preta",
                comoFazer: String(localized: "Molhe um pincel fino de cerdas curtas, encoste na sombra preta até virar uma pastinha e desenhe o traço com ela. Fica com acabamento fosco, mas a linha sai igualmente marcada.")
            ),
            Regra(
                substituto: "mascara de cílios",
                comoFazer: String(localized: "Se tiver um pincel fino,o umideçacom o rímel e use-o como delineador liquido.")
            )
        ],
        "lápis-preto":[
            Regra(
                substituto: "sombra-preta",
                comoFazer: String(localized: "Molhe um pincel fino de cerdas curtas, encoste na sombra preta até virar uma pastinha e aplique onde deseja. Fica com acabamento mais fosco e esfumado.")
            ),
        ],
        "clown": [
            Regra(
                substituto: "base",
                comoFazer: String(localized: "Aplique a base mais clara que você tem em camadas finas, esperando secar entre uma e outra, e sele cada camada com pó. Não fica opaco como o clown, mas constrói o contraste.")
            ),
            Regra(
                substituto: "po",
                comoFazer: String(localized: "Use o pó mais claro que tiver, com a esponja em batidinhas. A cobertura é mais leve — capriche na quantidade de camadas.")
            )
        ],
        "pancake": [
            Regra(
                substituto: "po",
                comoFazer: String(localized: "O papel do pancake aqui é selar para o clown não transferir. Pó solto em batidinhas com a esponja faz o mesmo trabalho, só exige uma camada mais generosa.")
            )
        ],
        "contorno": [
            Regra(
                substituto: "sombra-preta",
                comoFazer: String(localized: "Pegue pouquíssimo produto num pincel esfumado e vá construindo devagar — a sombra preta com mão leve vira o cinza do contorno. Comece com menos do que acha necessário.")
            ),
            Regra(
                substituto: "sombra-laranja",
                comoFazer: String(localized: "A sombra laranja fosca funciona como contorno quente, do tipo bronzer. Aplique nas laterais do nariz e esfume bem com a esponja úmida.")
            )
        ],
        "cilios-posticos": [
            Regra(
                substituto: "mascara-cilios",
                comoFazer: String(localized: "Faça três camadas de máscara, esperando secar entre elas, movendo o pincel em ziguezague na raiz. Não chega ao volume do postiço, mas abre bastante o olhar.")
            )
        ],
        "mascara-cilios": [
            Regra(
                substituto: "cilios-posticos",
                comoFazer: String(localized: "Se você não tem máscara de cílios mas tem cílios postiços, pode colar os cílios no lugar.")
            )
        ],
        "sombra-roxa": [
            Regra(
                substituto: "sombra-azul",
                comoFazer: String(localized: "Aplique a azul no côncavo e leve por cima um toque de magenta ou de batom vermelho esfumado com o dedo — a mistura puxa para o roxo.")
            ),
            Regra(
                substituto: "sombra-preta",
                comoFazer: String(localized: "Construa a profundidade com a preta esfumada e traga um brilho frio por cima. Perde o roxo, mas mantém o olhar profundo que a etapa pede.")
            )
        ],
        "sombra-azul": [
            Regra(
                substituto: "sombra-verde",
                comoFazer: String(localized: "A verde puxada para o azulado segura o mesmo efeito geométrico. Aplique bem pigmentada e conecte com o blush na têmpora do mesmo jeito.")
            )
        ],
        "sombra-branca": [
            Regra(
                substituto: "lapis-branco",
                comoFazer: String(localized: "Preencha o canto interno e a linha inferior com o lápis branco e esfume com o dedo. É o mesmo ponto de luz que a sombra branca cria.")
            ),
            Regra(
                substituto: "iluminador",
                comoFazer: String(localized: "Um toque de iluminador no canto interno e no centro da pálpebra faz a luz que abre o olhar.")
            )
        ],
        "sombra-preta": [
            Regra(
                substituto: "lapis-preto",
                comoFazer: String(localized: "Em alguns casos pode ser substituido pelo lápis preto com bastante cautela, aplicando um pouco e esfumando muito.")
            ),
            Regra(
                substituto: "contorno",
                comoFazer: String(localized: "No caso de contornos frios e acinzentados, eles podem substituir a sombra preta dando um efeito bem mais leve e apenas de profundidade nos olhos ou bochecas e nariz.")
            )
        ],

        "iluminador": [
            Regra(
                substituto: "sombra-branca",
                comoFazer: String(localized: "A própria sombra branca faz a faixa central do nariz — aplique com um pincel fino e esfume só nas bordas.")
            )
        ],
        "gloss": [
            Regra(
                substituto: "iluminador",
                comoFazer: String(localized: "Um ponto de iluminador cremoso no centro do lábio dá o brilho e o volume que o gloss traria.")
            )
        ],
        "lapis-labial": [
            Regra(
                substituto: "lapis-preto",
                comoFazer: String(localized: "Se for para desenhar o arco do cupido num visual escuro, o lápis de olho preto faz o contorno. Mantenha a ponta bem apontada.")
            )
        ],
        "lapis-branco": [
            Regra(
                substituto: "sombra-branca",
                comoFazer: String(localized: "Na ausência do lápis pode tentar esfumar sombra branca na linha d`água.")
            ),
            Regra(
                substituto: "iluminador",
                comoFazer: String(localized: "Na ausência do lápis pode tentar aplicar seu iluminador na linha d`água, com um pincel de sombra, o brilho ficará mais suave.")
            )

        ],
        "blush": [
            Regra(
                substituto: "batom",
                comoFazer: String(localized: "Batom cremoso funciona como blush: toque o dedo no produto, encoste nas maçãs e esfume rápido, antes de fixar.")
            ),
            Regra(
                substituto: "sombra-rosa",
                comoFazer: String(localized: "Sombra rosa funciona como blush: aplique sobre as maças e esfume bem, comece com pouco produto e vá espalhando e acrescentando mais se necessário.")
            )
        ],
        "batom": [
            Regra(
                substituto: "blush",
                comoFazer: String(localized: "Para tons rosados, pode dar umas batidinhas com blush na boca.")
            ),
            Regra(
                substituto: "sombra-rosa",
                comoFazer: String(localized: "Para tons rosados, pode dar umas batidinhas com sombra rosa na boca")
            ),
            Regra(
                substituto: "gloss",
                comoFazer: String(localized: "Na ausência do batom, as vezes, apenas o gloss já é satisfatório e adiciona cor aos lábios")
            ),

        ]

    ]
}
