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

    static func regiao(da categoria: CategoriaItem) -> String {
        switch categoria {
        case .batom, .gloss, .lapisLabial:
            "boca"
        case .sombra, .delineadorLiquido, .lapisOlho, .lapisOlhoBranco, .mascara, .sobrancelha, .ciliosPosticos:
            "olhos"
        case .base, .corretivo, .po, .blush, .contorno, .iluminador, .clown, .pancake:
            "rosto"
        }
    }


    static func fatoTecnico(da categoria: CategoriaItem) -> String {
        switch categoria {
        case .base:
            "Base é cobertura uniforme no tom da própria pele, aplicada no rosto todo — sem variante de cor."
        case .corretivo:
            "Corretivo cobre olheiras e manchas pontuais, no tom da pele ou um pouco mais claro — sem variante de cor."
        case .po:
            "Pó fixa a maquiagem e corta o brilho — translúcido ou no tom da pele, nunca colorido."
        case .blush:
            "Blush dá cor às maçãs do rosto pode ir na boca nem nos olhos."
        case .contorno:
            "Contorno é sempre num tom terroso/acastanhado, pra esculpir sombra — nunca colorido."
        case .iluminador:
            "Iluminador ilumina os pontos altos do rosto (maçãs, nariz, arco do cupido) — não é pigmento de cor."
        case .sombra:
            "Sombra é pálpebra — cada cor já é um produto do catálogo, nunca invente uma cor que não foi citada."
        case .delineadorLiquido:
            "Delineador líquido traça uma linha fina e definida rente aos cílios."
        case .lapisOlho:
            "Lápis de olho tem ponta macia — serve pra traços mais suaves ou esfumados que a caneta líquida."
        case .lapisOlhoBranco:
            "Lápis branco ilumina o canto interno do olho ou a linha d'água."
        case .mascara:
            "Máscara dá volume e curvatura aos próprios cílios."
        case .sobrancelha:
            "Produto de sobrancelha preenche falhas e define o formato — só na sobrancelha."
        case .batom:
            "Batom cobre o lábio inteiro, de forma opaca."
        case .gloss:
            "Gloss dá brilho e volume ao lábio, cobertura mais leve que o batom."
        case .lapisLabial:
            "Lápis labial contorna e preenche o lábio, geralmente por baixo do batom."
        case .clown:
            "Tinta clown é uma base branca opaca, pra contraste teatral no rosto todo."
        case .pancake:
            "Pancake sela a maquiagem numa camada fosca, por cima de outro produto de base."
        case .ciliosPosticos:
            "Cílios postiços vão colados sobre a linha dos cílios naturais, pra volume extra."
        }
    }

    static func aplicaveis(faltantes: [String], idsNaMaleta: Set<String>) -> [Par] {
        faltantes.compactMap { ausente in
            guard let regra = regras[ausente]?.first(where: { idsNaMaleta.contains($0.substituto) })
            else { return nil }
            return Par(ausente: ausente, regra: regra)
        }
    }

    static let semSubstituto = "Não achei um substituto razoável com o que você possui, vamos seguindo com a maquiagem."

    static let regras: [String: [Regra]] = [
        "caneta-delineadora": [
            Regra(
                substituto: "lapis-preto",
                comoFazer: "Aqueça a ponta do lápis por alguns segundos entre os dedos, trace a linha rente aos cílios em pequenos tracinhos e depois una tudo num traço só. Para o efeito de caneta, passe por cima de novo pressionando mais firme."
            ),
            Regra(
                substituto: "sombra-preta",
                comoFazer: "Molhe um pincel fino de cerdas curtas, encoste na sombra preta até virar uma pastinha e desenhe o traço com ela. Fica com acabamento fosco, mas a linha sai igualmente marcada."
            ),
            Regra(
                substituto: "mascara de cílios",
                comoFazer: "Se tiver um pincel fino,o umideçacom o rímel e use-o como delineador liquido."
            )
        ],
        "lápis-preto":[
            Regra(
                substituto: "sombra-preta",
                comoFazer: "Molhe um pincel fino de cerdas curtas, encoste na sombra preta até virar uma pastinha e aplique onde deseja. Fica com acabamento mais fosco e esfumado."
            ),
        ],
        "clown": [
            Regra(
                substituto: "base",
                comoFazer: "Aplique a base mais clara que você tem em camadas finas, esperando secar entre uma e outra, e sele cada camada com pó. Não fica opaco como o clown, mas constrói o contraste."
            ),
            Regra(
                substituto: "po",
                comoFazer: "Use o pó mais claro que tiver, com a esponja em batidinhas. A cobertura é mais leve — capriche na quantidade de camadas."
            )
        ],
        "pancake": [
            Regra(
                substituto: "po",
                comoFazer: "O papel do pancake aqui é selar para o clown não transferir. Pó solto em batidinhas com a esponja faz o mesmo trabalho, só exige uma camada mais generosa."
            )
        ],
        "contorno": [
            Regra(
                substituto: "sombra-preta",
                comoFazer: "Pegue pouquíssimo produto num pincel esfumado e vá construindo devagar — a sombra preta com mão leve vira o cinza do contorno. Comece com menos do que acha necessário."
            ),
            Regra(
                substituto: "sombra-laranja",
                comoFazer: "A sombra laranja fosca funciona como contorno quente, do tipo bronzer. Aplique nas laterais do nariz e esfume bem com a esponja úmida."
            )
        ],
        "cilios-posticos": [
            Regra(
                substituto: "mascara-cilios",
                comoFazer: "Faça três camadas de máscara, esperando secar entre elas, movendo o pincel em ziguezague na raiz. Não chega ao volume do postiço, mas abre bastante o olhar."
            )
        ],
        "mascara-cilios": [
            Regra(
                substituto: "cilios-posticos",
                comoFazer: "Se você não tem máscara de cílios mas tem cílios postiços, pode colar os cílios no lugar."
            )
        ],
        "sombra-roxa": [
            Regra(
                substituto: "sombra-azul",
                comoFazer: "Aplique a azul no côncavo e leve por cima um toque de magenta ou de batom vermelho esfumado com o dedo — a mistura puxa para o roxo."
            ),
            Regra(
                substituto: "sombra-preta",
                comoFazer: "Construa a profundidade com a preta esfumada e traga um brilho frio por cima. Perde o roxo, mas mantém o olhar profundo que a etapa pede."
            )
        ],
        "sombra-azul": [
            Regra(
                substituto: "sombra-verde",
                comoFazer: "A verde puxada para o azulado segura o mesmo efeito geométrico. Aplique bem pigmentada e conecte com o blush na têmpora do mesmo jeito."
            )
        ],
        "sombra-branca": [
            Regra(
                substituto: "lapis-branco",
                comoFazer: "Preencha o canto interno e a linha inferior com o lápis branco e esfume com o dedo. É o mesmo ponto de luz que a sombra branca cria."
            ),
            Regra(
                substituto: "iluminador",
                comoFazer: "Um toque de iluminador no canto interno e no centro da pálpebra faz a luz que abre o olhar."
            )
        ],
        "iluminador": [
            Regra(
                substituto: "sombra-branca",
                comoFazer: "A própria sombra branca faz a faixa central do nariz — aplique com um pincel fino e esfume só nas bordas."
            )
        ],
        "gloss": [
            Regra(
                substituto: "iluminador",
                comoFazer: "Um ponto de iluminador cremoso no centro do lábio dá o brilho e o volume que o gloss traria."
            )
        ],
        "lapis-labial": [
            Regra(
                substituto: "lapis-preto",
                comoFazer: "Se for para desenhar o arco do cupido num visual escuro, o lápis de olho preto faz o contorno. Mantenha a ponta bem apontada."
            )
        ],
        "lapis-branco": [
            Regra(
                substituto: "sombra-branca",
                comoFazer: "Na ausência do lápis pode tentar esfumar sombra branca na linha d`água."
            ),
            Regra(
                substituto: "iluminador",
                comoFazer: "Na ausência do lápis pode tentar aplicar seu iluminador na linha d`água, com um pincel de sombra, o brilho ficará mais suave."
            )

        ],
        "blush": [
            Regra(
                substituto: "batom",
                comoFazer: "Batom cremoso funciona como blush: toque o dedo no produto, encoste nas maçãs e esfume rápido, antes de fixar."
            ),
            Regra(
                substituto: "sombra-rosa",
                comoFazer: "Sombra rosa funciona como blush: aplique sobre as maças e esfume bem, comece com pouco produto e vá espalhando e acrescentando mais se necessário."
            )
        ]
    ]
}
