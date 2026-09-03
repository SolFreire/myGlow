//
//  StaticRulesSuggester.swift
//  myGlow
//

import Foundation

/// Fallback para aparelhos sem Apple Intelligence.
///
/// Não inventa nada: os passos vêm das próprias falas de instrução do roteiro e
/// as substituições vêm de uma tabela curada. Por isso `itensNaoUtilizados`
/// volta sempre vazio — esse campo existe para *restringir o modelo*, e aqui não
/// há modelo nenhum para restringir.
nonisolated struct StaticRulesSuggester: TechniqueSuggesting {
    struct Regra: Sendable {
        let substituto: String
        let comoFazer: String
    }

    let roteiro: Roteiro

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        let maleta = inventory
        let idsNaMaleta = Set(maleta.map(\.id))
        let faltantes = step.itensFaltantes(naMaleta: idsNaMaleta)

        let substituicoes = faltantes.compactMap { ausente -> TechniqueSuggestion.Substituicao? in
            guard let regra = Self.regras[ausente]?.first(where: { idsNaMaleta.contains($0.substituto) })
            else { return nil }
            return TechniqueSuggestion.Substituicao(
                itemAusente: CatalogoMaquiagem.nome(paraID: ausente),
                itemUsado: CatalogoMaquiagem.nome(paraID: regra.substituto),
                comoFazer: regra.comoFazer
            )
        }

        let passos = step.falas
            .filter { $0.tipo == .instrucaoPratica || $0.tipo == .instrucaoPraticaTecnica }
            .map(\.texto)

        let curiosidade = step.falas
            .first { $0.tipo == .contextoHistorico || $0.tipo == .contexto || $0.tipo == .discussao }?
            .texto ?? roteiro.briefing

        return TechniqueSuggestion(
            passos: passos,
            substituicoes: substituicoes,
            itensNaoUtilizados: [],
            curiosidade: curiosidade,
            itensForaDaMaleta: ChecagemDeInventario.itensForaDaMaleta(
                emTextos: passos + substituicoes.map(\.comoFazer),
                maleta: maleta
            ),
            origem: .regrasEstaticas
        )
    }

    /// Tabela curada de substituições, do item ausente para o que pode fazer o
    /// papel dele. A ordem importa: a primeira regra cujo substituto está na
    /// maleta é a escolhida.
    static let regras: [String: [Regra]] = [
        "caneta-delineadora": [
            Regra(
                substituto: "lapis-preto",
                comoFazer: "Aqueça a ponta do lápis por alguns segundos entre os dedos, trace a linha rente aos cílios em pequenos tracinhos e depois una tudo num traço só. Para o efeito de caneta, passe por cima de novo pressionando mais firme."
            ),
            Regra(
                substituto: "sombra-preta",
                comoFazer: "Molhe um pincel fino de cerdas curtas, encoste na sombra preta até virar uma pastinha e desenhe o traço com ela. Fica com acabamento fosco, mas a linha sai igualmente marcada."
            )
        ],
        "clown": [
            Regra(
                substituto: "base",
                comoFazer: "Aplique a base mais clara que você tem em camadas finas, esperando secar entre uma e outra, e sele cada camada com pó. Não fica opaco como o clown, mas constrói o contraste."
            ),
            Regra(
                substituto: "po",
                comoFazer: "Use o pó mais claro que tiver, aplicado úmido com a esponja em batidinhas. A cobertura é mais leve — capriche na quantidade de camadas."
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
        "blush": [
            Regra(
                substituto: "batom",
                comoFazer: "Batom cremoso funciona como blush: toque o dedo no produto, encoste nas maçãs e esfume rápido, antes de fixar."
            )
        ]
    ]
}
