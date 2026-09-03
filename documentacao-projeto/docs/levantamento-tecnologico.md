# Levantamento de Tecnologias — App de Maquiagem Gamificado (iOS)

Documento de referência técnica para o app gameficado sobre maquiagem (subculturas gótica, gyaru e new romantic), conduzido em um salão virtual. Cobre a stack recomendada para: cadastro de itens de maquiagem, trilha de experiência guiada por personagem, sugestões de técnica via IA on-device baseadas no inventário do usuário, captura de foto, edição com elementos da subcultura e compartilhamento/salvamento local.

_Última atualização: 24/08/2026._

## Resumo das recomendações

| Necessidade | Tecnologia recomendada | Por quê |
|---|---|---|
| Linguagem e UI | Swift + SwiftUI | Padrão atual da Apple, produtividade alta, integra nativamente com o restante da stack abaixo |
| IA para sugestão de técnicas | Foundation Models framework (on-device) | Roda local, gratuito, privado; usa o inventário cadastrado como contexto |
| Cadastro de maquiagens / progresso | SwiftData | Sucessor moderno do Core Data, integração nativa com SwiftUI |
| Captura de foto | AVFoundation (câmera custom) ou PhotosPicker | Depende do nível de controle de UI desejado na cena de captura |
| Edição da foto final | SwiftUI + `ImageRenderer` (Core Image só se entrar filtro/blend mode) | Stickers e molduras são composição de views, não processamento de pixel |
| Compartilhar/salvar | ShareLink + PhotosUI (PHPhotoLibrary) | APIs nativas de compartilhamento e salvamento no rolo da câmera |
| Sincronizar entre dispositivos (opcional) | CloudKit | Sem backend próprio, usa a conta iCloud do usuário |
| Gamificação (opcional) | GameKit / Game Center | Conquistas e progresso sem construir sistema próprio |

## 1. Plataforma e linguagem

- **Swift** como linguagem e **SwiftUI** como framework de UI — é o caminho nativo recomendado pela Apple para apps novos e se integra diretamente com SwiftData, Foundation Models e PhotosUI.
- **Xcode** como IDE/toolchain de build, teste e distribuição.
- Decisão de versão mínima de iOS é a mais importante do projeto, porque trava o que fica disponível para a funcionalidade de IA (seção 2). Duas rotas:
  - **iOS 26 como mínimo**: dá acesso direto ao Foundation Models framework sem lógica condicional, mas exclui usuários em versões/dispositivos mais antigos.
  - **iOS 18 (ou versão anterior) como mínimo, com feature detection**: a maior parte da experiência (cadastro, trilha guiada, câmera, edição, compartilhamento) funciona em versões mais antigas; a sugestão por IA verifica `SystemLanguageModel.availability` em tempo de execução e cai para um conteúdo estático/regras pré-definidas quando indisponível.

## 2. IA generativa on-device — Foundation Models framework

Este é o componente mais específico do projeto: usar o inventário de maquiagens cadastrado pelo usuário para que o personagem sugira técnicas alternativas (ex.: "sem delineador líquido? oriento como fazer com lápis").

**O que é:** framework nativo da Apple (introduzido no iOS 26) que expõe o modelo de linguagem on-device usado pela Apple Intelligence, para uso direto em apps de terceiros.

**Peças principais da API:**
- `SystemLanguageModel` — ponto de acesso ao modelo; é preciso checar `availability` (`.available` / `.unavailable(reason)`) antes de usar.
- `LanguageModelSession` — mantém contexto/histórico da conversa; é inicializada com instruções, guardrails e ferramentas (tools).
- `@Generable` e `@Guide` (macros) — permitem pedir **saída estruturada** (JSON tipado) em vez de texto livre — ideal para retornar, por exemplo, `{ tecnica: String, substituicoes: [String], passoAPasso: [String] }` a partir do inventário do usuário.
- **Tool calling** — o modelo pode chamar funções Swift customizadas (ex.: "consultar itens cadastrados do usuário") via o protocolo `Tool`, o que evita ter que injetar o inventário inteiro no prompt toda vez.
- `streamResponse()` — resposta em streaming (token a token), útil para a sensação de "personagem falando em tempo real" na tela de tutorial.

**Requisitos e limitações importantes:**
- Exige **iOS 26+** e um dispositivo compatível com Apple Intelligence — na prática, **iPhone 15 Pro/Pro Max ou mais recente** (chip A17 Pro ou superior) com Apple Intelligence habilitado nas configurações (também depende de idioma/região habilitados pela Apple).
- Um guardrail de conteúdo é sempre aplicado pela Apple e não pode ser desativado — relevante para revisar tom/conteúdo que o personagem pode gerar.
- Roda majoritariamente on-device; para prompts mais complexos a Apple pode usar Private Cloud Compute (infraestrutura própria da Apple, não é uma chamada de rede genérica).
- Ainda pode carregar rótulo de beta/API sujeita a mudanças conforme a versão do SDK usada — vale conferir a documentação da versão de Xcode que o time for usar.

**Novidade relevante (WWDC26):** a Apple abriu o Foundation Models framework para **provedores de LLM de terceiros** (incluindo Gemini e Claude/Anthropic) através de um protocolo público (`LanguageModel` / `LanguageModelExecutor`). Na prática, o mesmo código de `LanguageModelSession` passa a funcionar com outro provedor por trás, sem reescrever a lógica de sessão. Isso abre uma estratégia interessante para este app:

- **On-device (Apple Intelligence) como padrão** para quem tem hardware compatível — grátis, privado, funciona offline.
- **Fallback opcional via provedor de nuvem** (mesmo protocolo) para dispositivos sem Apple Intelligence, mantendo a mesma interface de código.
- Importante: chamar um provedor de nuvem exige guardar a chave de API fora do app (client-side não é seguro para isso) — ou seja, esse caminho implica um **pequeno backend/proxy** (ver seção 7) só para intermediar essas chamadas com segurança.

## 3. Cadastro e persistência local — SwiftData

Para o inventário de maquiagens do usuário, progresso na trilha e preferências:

| | SwiftData | Core Data |
|---|---|---|
| Integração com SwiftUI | Nativa (`@Model`, `@Query`) | Requer mais boilerplate (`NSFetchedResultsController` ou wrappers) |
| Curva de aprendizado | Mais simples, sintaxe Swift moderna | Mais verboso, baseado em Objective-C/NSManagedObject |
| Maturidade/controle fino | Mais nova, menos controle de baixo nível | Mais madura, mais controle (migrations complexas, CloudKit avançado) |
| Recomendação para este projeto | ✅ Recomendado — modelo de dados é relativamente simples (itens de maquiagem, personagens, progresso, fotos salvas) | Alternativa se o time já tem código/experiência em Core Data ou precisar de migrations muito específicas |

SwiftData também integra com CloudKit de forma mais direta, o que facilita a sincronização opcional entre dispositivos (seção 6).

### Cadastro por seleção, não por digitação

Decisão do time: o cadastro não é um campo de texto livre — o usuário **seleciona** o item numa lista ilustrada de opções pré-definidas (catálogo com ícone/ilustração por item, curado pelo time de design; hoje desenhado como arrastar o item até a cesta da categoria correspondente, seção 6). Isso muda o que a camada de dados precisa tratar:

- **Não existe validação de texto livre** (campo vazio, caracteres inválidos, nome mal formatado) — essa classe inteira de erro simplesmente não ocorre, porque a entrada já vem de uma seleção fechada e válida.
- O catálogo ilustrado em si (nomes, ícones, associação com subcultura/categoria) é conteúdo estático — vive como asset/JSON no bundle do app, não como dado gerado pelo usuário, e é responsabilidade do design, não da camada de persistência.
- A única validação que ainda faz sentido no cadastro é de **duplicidade** (o mesmo item sendo arrastado/selecionado duas vezes) — e mesmo essa pode ser resolvida na própria UI (ex.: item já cadastrado fica com aparência "desabilitado" no catálogo) em vez de uma checagem no código de persistência.

## 4. Câmera, mídia e edição de imagem

- **Captura da foto final:**
  - `PhotosPicker` (PhotosUI) se bastar deixar o usuário tirar a foto pelo app de Câmera do sistema ou escolher uma existente.
  - `AVFoundation` / `AVCaptureSession` se for necessário uma **tela de câmera customizada dentro do app** (por exemplo, com overlay do espelho do salão já visível durante a captura, no estilo da experiência).
- **Edição pós-captura (aplicar elementos da subcultura):**
  - **Posicionamento dos stickers, em tela:** SwiftUI puro resolve — um `ZStack` com a foto base e cada sticker como uma `Image`, posicionado por gestos (`DragGesture` + `MagnificationGesture` + `RotationGesture` combinados). Não precisa de Core Image pra isso; é composição de views, não processamento de pixel.
  - **Achatar a composição final (pra salvar/compartilhar):** `ImageRenderer` (SwiftUI, iOS 16+) — renderiza a própria hierarquia de views (foto + stickers já posicionados) direto para um `UIImage`, sem duplicar a lógica de posição numa segunda camada. Alternativa mais manual, se precisar de mais controle: `UIGraphicsImageRenderer` (Core Graphics), desenhando cada camada com as transformações de posição/rotação/escala.
  - **Core Image / `CIFilter`** só entra se, além dos stickers, algum filtro de cor/tom ou blend mode for adicionado depois (ex.: um brilho tipo "screen" atrás de um sticker, granulado, ajuste de saturação). Para colagem pura de elementos estáticos, sem nenhum processamento de pixel, ele é mais maquinário do que o necessário — vale guardar para quando (e se) entrar um efeito de verdade.
  - **Metal** segue de fora por enquanto — só necessário se entrarem efeitos mais elaborados (partículas, distorção) no futuro; overlays estáticos não precisam disso.

## 5. Compartilhamento e salvamento local

- **`ShareLink`** (SwiftUI, encapsula o `UIActivityViewController`) para compartilhar a foto editada em outros apps.
- **`PhotosUI` / `PHPhotoLibrary`** para salvar a foto no rolo da câmera do dispositivo, com o pedido de permissão correspondente.
- Configurar em `Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryAddUsageDescription` (e `NSPhotoLibraryUsageDescription` se também for necessário *ler* fotos existentes).

## 6. Interface, navegação e narrativa dos personagens

### Interação de cadastro — arrastar maquiagem para a cesta

O design pediu, na tela de cadastro, uma interação de arrastar cada item de maquiagem até uma "cesta" correspondente ao tipo dela (batom, delineador, etc.). É um drag-and-drop simples de UI — sem física, colisão ou câmera de jogo — então **não precisa de SpriteKit**: as APIs nativas do SwiftUI já cobrem isso.

Duas formas de implementar, dependendo do quanto de customização visual o design quer:

- **`.draggable(_:)` + `.dropDestination(for:action:)`** (SwiftUI, iOS 16+): caminho mais simples — o item vira "arrastável" e a cesta vira um alvo de soltura via o protocolo `Transferable`. Menos código, mas menos controle sobre a prévia do arraste e o feedback visual durante o gesto.
- **`DragGesture` manual** + checagem de sobreposição de `frame`/`GeometryReader`: mais código, mas dá controle total sobre a animação — item "voando" até a cesta, cesta destacando/brilhando quando o item passa por cima, o item voltando com uma animação de mola (`.spring()`) se soltar fora do alvo. Combinado com `.sensoryFeedback` (iOS 17+) ou `UIImpactFeedbackGenerator`, dá aquele "click" tátil no momento em que o item entra na cesta.

Para uma interação pensada pelo time de design com esse nível de capricho (feedback visual/tátil no drop), a rota de `DragGesture` manual tende a entregar o resultado que eles estão imaginando; `.draggable`/`.dropDestination` é a opção mais rápida se o visual padrão do sistema já for suficiente.

- **SwiftUI** com `NavigationStack`/`NavigationSplitView` para a jornada: salão → escolha da subcultura/personagem → tutorial guiado → sugestão de IA → captura → edição → compartilhar.
- **Animações**: `SwiftUI Animation`/`PhaseAnimator` para transições nativas; **Lottie** (pacote `lottie-ios`) é uma opção madura se os personagens forem ilustrados em animação vetorial (comum em apps de personagem/mascote).
- **Narração/áudio (opcional):** `AVAudioPlayer` para áudio pré-gravado do personagem (melhor qualidade de voz/interpretação) ou `AVSpeechSynthesizer` para narrar texto gerado dinamicamente (mais barato de produzir, qualidade de voz sintética).

### Orientação no iPad e o novo sistema de janelas (iPadOS 26)

A partir do iPadOS 26, a Apple depreciou a chave `UIRequiresFullScreen` — o mecanismo antigo que fazia um app recusar totalmente a multitarefa (Split View, Slide Over, Stage Manager) e rodar sempre em tela cheia numa única orientação. Ela ainda funciona hoje, mas a Apple já confirmou que será **ignorada a partir de apps compilados com o SDK do iOS/iPadOS 27** — não vale construir a experiência em cima dela.

O que continua valendo pra restringir orientação (ex.: travar em landscape) é a chave de sempre:

```xml
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

**Atenção — bug conhecido:** há reports (já reconhecidos pela Apple DTS) de que no iPadOS 26, com o bloqueio de rotação do Central de Controle **desligado**, o sistema às vezes ignora essa restrição e vira o app pra portrait mesmo assim, principalmente ao voltar de background ou desbloquear o device. Testar sempre com o bloqueio de rotação ligado durante o desenvolvimento; se o bug aparecer em produção, é caso de Feedback Assistant, não de configuração errada.

Pra travar orientação só em uma tela específica (ex.: não girar durante a captura de foto), a API atual é:

```swift
override var prefersInterfaceOrientationLocked: Bool {
    return estaCapturandoFoto
}
// chamar setNeedsUpdateOfPrefersInterfaceOrientationLocked() quando o valor mudar
```

Vale lembrar que essa é uma preferência — o sistema não garante que vai respeitar, diferente da garantia que o `UIRequiresFullScreen` antigo dava.

**Consequência de design:** como o iPad agora pode rodar o app numa janela de qualquer tamanho (não só "portrait" ou "landscape" no sentido antigo), o caminho mais seguro é desenhar telas com conteúdo denso — como a de Tutorial, com personagem + chat/sugestão de técnica — para se adaptarem ao espaço disponível, em vez de assumir uma orientação fixa. Práticas recomendadas:

- Decidir o layout pelo **espaço disponível**, não pela orientação do device: usar `@Environment(\.horizontalSizeClass)`/`verticalSizeClass`, ou o próprio `ViewThatFits`.
- **`ViewThatFits`** para alternar automaticamente entre "personagem e chat lado a lado" (bastante largura) e "personagem compacto em cima, chat ocupando o resto embaixo" (pouca largura) — sem precisar de `if isLandscape`.
- Evitar `.frame(width:height:)` com valores fixos em telas de conteúdo importante; preferir tamanho relativo ao espaço disponível (`GeometryReader` ou `.containerRelativeFrame`, iOS 17+).
- Definir hierarquia do que encolhe primeiro quando o espaço aperta: conteúdo essencial (chat, botões de ação) mantém tamanho garantido; conteúdo decorativo (ilustração do personagem em corpo inteiro) é o que reduz ou corta.
- Nas cestas de drag-and-drop do cadastro, usar `LazyVGrid` com `GridItem(.adaptive(minimum:))` em vez de fixar quantidade de colunas — o grid se reorganiza sozinho conforme o espaço.
- Testar no Xcode Preview com `previewLayout(.fixed(width:height:))` em tamanhos variados (não só "iPhone"/"iPad" padrão), incluindo tamanhos de janela pequena — é o cenário mais parecido com o app rodando redimensionado no novo sistema de janelas do iPad.

## 7. Gamificação e progresso

- Sistema de progresso/pontos pode ser modelado com **SwiftData** (entidades de conquistas, maquiagens completadas, subculturas exploradas).
- **GameKit / Game Center** é opcional e vale a pena se quiser conquistas (achievements) e ranking padronizados pela Apple sem construir infraestrutura própria.

## 8. Sincronização entre dispositivos e backend (opcional)

- **CloudKit**: forma mais simples de sincronizar o cadastro de maquiagens e progresso entre iPhone/iPad do mesmo usuário via iCloud, sem precisar manter servidor próprio. Integra bem com SwiftData (`.modelContainer(for:cloudKitDatabase:)`).
- **Backend próprio (leve), somente se for usar IA em nuvem como fallback** (seção 2): um proxy simples (ex.: Cloudflare Workers, Vercel Functions ou AWS Lambda) cuja única função é guardar a chave de API do provedor de LLM e repassar a chamada — nunca embutir a chave diretamente no app.
- Não é necessário backend próprio só para a funcionalidade descrita hoje (cadastro, tutorial, IA on-device, foto, compartilhar) — CloudKit cobre a sincronização, e o Foundation Models on-device não depende de servidor.

## 9. Testes e qualidade

- **Swift Testing** (framework de testes mais novo da Apple) e/ou **XCTest** para testes unitários (regras de sugestão de técnica, modelos de dados).
- **XCUITest** para testes de fluxo de UI (jornada completa: cadastro → tutorial → foto → compartilhar).
- Testes de snapshot (ex.: `swift-snapshot-testing`) são úteis para garantir consistência visual das telas de cada subcultura ao longo do desenvolvimento.

## 10. Distribuição e CI/CD

- **Xcode Cloud** (integrado à Apple) ou **GitHub Actions + fastlane** para build, testes automatizados e envio ao TestFlight.
- **TestFlight** para testes beta com usuárias/usuários reais antes do lançamento.
- **App Store Connect** para publicação final.

## 11. Requisitos de dispositivo — resumo de compatibilidade

| Funcionalidade | iOS mínimo | Hardware mínimo |
|---|---|---|
| Cadastro, tutorial, câmera, edição, compartilhar | iOS 17–18 (ampla compatibilidade) | Qualquer iPhone suportado por essa versão de iOS |
| Sugestão de técnica via Foundation Models (on-device) | iOS 26+ | iPhone 15 Pro/Pro Max ou mais recente (A17 Pro+), com Apple Intelligence habilitado |
| Sugestão de técnica via provedor de nuvem (fallback opcional) | Qualquer versão suportada pelo app | Qualquer dispositivo com internet — requer backend proxy próprio |

## 12. Explorar depois (fora do escopo inicial)

### Prioridade para a v2 — Create ML no cadastro de maquiagens

Decisão do time: se der tempo, a segunda versão estável explora **Create ML** para acelerar o cadastro — a usuária fotografa o item de maquiagem e o app sugere automaticamente o tipo/categoria (batom, delineador, sombra etc.), em vez de preencher tudo manualmente.

O que isso envolve, para dimensionar o esforço quando chegar a hora:

- **Dado de treino**: um conjunto de fotos rotuladas por categoria de item (quanto mais variado — ângulo, marca, embalagem —, melhor a generalização). É tipicamente o maior custo do recurso, não o código.
- **Treinamento**: **Create ML** oferece dois caminhos — o **app Create ML** (interface visual, sem código, arrasta o dataset e treina um classificador de imagem) ou o **framework Create ML** em Swift/Playground (mesmo processo, porém programático e versionável). Para um classificador de categorias de maquiagem, o app já costuma bastar.
- **Integração no app**: o modelo treinado exporta como `.mlmodel`/`.mlpackage` e entra no app via **Core ML** + **Vision** (`VNCoreMLRequest`) — a foto tirada no cadastro passa pelo modelo, que devolve a categoria sugerida (com a usuária podendo corrigir se errar).
- **Convive com o Foundation Models**: são complementares, não concorrentes — Create ML classifica *o que é* o item a partir da imagem; Foundation Models sugere *a técnica* a partir do inventário já cadastrado (incluindo os itens que o Create ML ajudou a cadastrar mais rápido).

Vale já reservar, na v1, um ponto de extensão simples no fluxo de cadastro (ex.: um passo opcional de "fotografar o item") para que a v2 plugue o classificador sem redesenhar a tela.

### Mais além (sem prazo definido)

- **ARKit + RealityKit**: prova de maquiagem em tempo real sobre o rosto ao vivo (filtro de câmera), caso o produto evolua da edição pós-foto para um "provador" ao vivo.
- **Vision framework**: detecção de pontos do rosto (olhos, lábios) para alinhar automaticamente os overlays da subcultura na foto final, em vez de posicionamento manual.

## 13. Arquitetura de código sugerida

**Padrão:** MVVM com o framework **Observation** (`@Observable`, iOS 17+) em vez do antigo `ObservableObject` — menos boilerplate e re-renderiza só o que realmente mudou. Organização por **feature** (pasta por tela/fluxo), não por tipo de arquivo, porque o app tem um fluxo bem definido (salão → cadastro → tutorial → IA → câmera → edição → compartilhar) e cada etapa tende a evoluir de forma independente.

O Xcode já cria, por padrão, dois níveis de pasta "MaquiagemApp" — uma externa (a raiz do repositório) e uma interna (a raiz do código-fonte do target). A estrutura por feature entra **dentro** da pasta interna; não é preciso criar um nível novo, só organizar o que já existe:

```
MaquiagemApp/                          ← raiz do repositório (Git)
├── MaquiagemApp.xcodeproj
├── README.md
├── CONTRIBUTING.md
├── .gitignore
│
├── MaquiagemApp/                      ← raiz do código-fonte do target (o que o Xcode chama de "pasta do projeto")
│   ├── App/
│   │   ├── MaquiagemApp.swift            // @main — monta o ModelContainer e injeta os serviços
│   │   └── AppEnvironment.swift          // container leve de dependências compartilhadas
│   │
│   ├── Core/                             // código sem UI, reaproveitado pelas features
│   │   ├── Persistence/
│   │   │   ├── Models/                   // @Model (SwiftData): MakeupItem, Character, UserProgress, Achievement
│   │   │   └── Repositories/             // MakeupInventoryRepository, ProgressRepository
│   │   ├── AI/
│   │   │   ├── TechniqueSuggesting.swift         // protocolo
│   │   │   ├── FoundationModelsSuggester.swift   // implementação on-device
│   │   │   ├── CloudFallbackSuggester.swift      // implementação via provedor externo (opcional, WWDC26)
│   │   │   └── MakeupItemClassifying.swift       // protocolo p/ Create ML — stub na v1, implementado na v2
│   │   ├── Media/
│   │   │   ├── CameraService.swift        // AVFoundation
│   │   │   ├── PhotoEditor.swift          // ImageRenderer + overlays da subcultura
│   │   │   └── PhotoLibraryService.swift  // salvar / compartilhar
│   │   └── DesignSystem/                  // cores, tipografia, componentes (ex.: cesta de drop, item arrastável)
│   │
│   ├── Features/
│   │   ├── Salao/            // tela inicial — escolha de subcultura/personagem
│   │   ├── Cadastro/         // inventário + arrastar item para a cesta
│   │   ├── Tutorial/         // trilha guiada pelo personagem + chamada à IA
│   │   ├── Camera/           // captura da foto final
│   │   ├── Edicao/           // aplicar elementos da subcultura
│   │   ├── Compartilhamento/ // ShareLink / salvar no rolo
│   │   └── Gamificacao/      // progresso e conquistas
│   │   (cada uma com View + ViewModel; Route quando precisar de sub-navegação)
│   │
│   ├── Navigation/
│   │   └── AppRoute.swift    // enum de rotas + NavigationStack raiz
│   │
│   ├── Assets.xcassets/                  // catálogo de imagens/cores — organizado por pastas dentro do catálogo
│   │   ├── AppIcon.appiconset
│   │   ├── Colors/                       // paleta do DesignSystem, se versionada como color set
│   │   ├── Personagens/                  // ilustrações de cada personagem/subcultura
│   │   ├── Salao/                        // arte de fundo da cena do salão
│   │   └── Cadastro/                     // ícones do catálogo ilustrado de itens de maquiagem
│   └── Preview Content/
│       └── Preview Assets.xcassets       // assets usados só nos #Preview do SwiftUI, não vão pro app final
│
├── MaquiagemAppTests/                    // alvo de testes (Swift Testing)
└── MaquiagemAppUITests/                  // alvo de UI tests (XCUITest)
```

`Assets.xcassets` e `Preview Content` ficam no mesmo nível de `App/`, `Core/`, `Features/` e `Navigation/` — são pastas que o próprio Xcode já cria ao gerar o projeto, então não é preciso mover nada, só criar subpastas dentro do catálogo de assets seguindo o mesmo nome das features (o Xcode trata cada subpasta do `.xcassets` como um agrupamento visual; ativando "Provides Namespace" nela, o nome da pasta também vira prefixo do nome do asset em código, o que ajuda a não colidir nomes entre features). `README.md`, `CONTRIBUTING.md` e `.gitignore` ficam na raiz do repositório, fora da pasta do target — são arquivos sobre o projeto como um todo, não sobre o app em si.

**Por que isolar a IA e o Create ML atrás de protocolo:** a ViewModel do Tutorial não deveria saber se a sugestão veio do modelo on-device, de um provedor de nuvem (fallback do WWDC26) ou, mais pra frente, se o item veio de um cadastro manual ou classificado pelo Create ML. Isso é o que permite trocar a implementação sem tocar em UI, e testar a ViewModel com um mock em vez de precisar de um iPhone 15 Pro rodando os testes.

```swift
protocol TechniqueSuggesting {
    func suggestTechnique(
        for step: TutorialStep,
        inventory: [MakeupItem]
    ) async throws -> TechniqueSuggestion
}

enum TechniqueSuggesterFactory {
    static func make() -> TechniqueSuggesting {
        switch SystemLanguageModel.default.availability {
        case .available:
            return FoundationModelsSuggester()
        case .unavailable:
            // troque por StaticRulesSuggester() se não quiser depender de um backend próprio
            return CloudFallbackSuggester()
        }
    }
}
```

`MakeupItemClassifying` segue o mesmo desenho: na v1, uma implementação `ManualEntryClassifier` (não faz nada, é preenchimento manual mesmo); na v2, troca por `CreateMLClassifier` sem mexer na tela de cadastro.

**Persistência:** os `@Model` do SwiftData ficam em `Core/Persistence/Models`; acesso a eles passa por um repositório fino (`MakeupInventoryRepository`, `ProgressRepository`) em vez de `@Query` espalhado pelas Views — facilita trocar a fonte de dados (ex.: adicionar CloudKit depois) e testar com um `ModelConfiguration(isStoredInMemoryOnly: true)`.

**Injeção de dependência:** para o tamanho deste app, um `AppEnvironment` simples (struct ou `@Observable final class` com os serviços como propriedades) injetado via `.environment()` no root da `App` é suficiente — evita a complexidade de um framework de DI.

**Testes:** ViewModels testadas com mocks dos protocolos acima (`TechniqueSuggesting`, `MakeupItemClassifying`, repositórios); Views cobertas por XCUITest no fluxo ponta a ponta (seção 9).

**Modularização (só se o time crescer):** para a v1, a estrutura de pastas acima dentro de um único target já basta. Se a equipe crescer ou o build começar a pesar, cada pasta de `Core/` vira um Swift Package local (`DesignSystem`, `Persistence`, `AI`, `Media`) — é um refactor mecânico porque as dependências já estão isoladas por protocolo desde o início.

### Por que MVVM e não TCA (The Composable Architecture)

MVVM não é "a melhor arquitetura" em termos absolutos — é a escolha certa **para o formato atual deste projeto**. TCA (biblioteca de terceiros da Point-Free, baseada em State/Action/Reducer/Effect, no estilo Redux/Elm) é tecnicamente mais rigorosa em alguns pontos: testa efeitos assíncronos de forma determinística (bom para testar o streaming do Foundation Models sem depender de tempo real), força que toda mudança de estado passe por um único lugar (o reducer), e escala bem quando várias features precisam compor estado entre si.

O motivo de não adotar agora:

- **Ceremônia vs. tamanho do time/prazo.** TCA pede modelar cada ação como caso de um enum e cada tela como reducer — vale a pena quando o estado é complexo e compartilhado entre muitas features; para uma jornada majoritariamente linear (seção 6) com um time pequeno correndo pra validar a PoC (seção 14) e esperando as artes, isso é ceremônia sem retorno proporcional agora.
- **Curva de aprendizado e contratação.** MVVM + `@Observable` é o padrão que a própria Apple ensina e que a maioria dos devs iOS já conhece; TCA exige onboarding específico (reducers, effects, macros `@Reducer`/`@ObservableState`) — mais fricção pra quem entrar no time depois.
- **Dependência de terceiro.** TCA é mantido pela Point-Free, não pela Apple — maduro e amplamente usado, mas ainda é uma peça a mais fora do controle da equipe, incluindo tempo de compilação adicional pelas macros.
- **A parte que mais precisava de rigor de teste já está coberta.** O ponto forte do TCA (testar efeitos assíncronos e trocar implementações de forma controlada) já foi resolvido aqui isolando IA e Create ML atrás de protocolo (`TechniqueSuggesting`, `MakeupItemClassifying`) — dá boa parte do benefício de testabilidade do TCA sem adotar a arquitetura inteira.

Vale reconsiderar TCA se, mais pra frente, o app ganhar bastante estado cruzado entre features (ex.: gamificação afetando várias telas ao mesmo tempo, navegação profunda com deep linking) — e a migração não seria do zero, já que a camada `Core/AI` isolada por protocolo entra num reducer do TCA sem precisar ser reescrita.

## 14. PoC do Foundation Models — para rodar em paralelo às artes

Enquanto a equipe técnica/design fecha ilustrações e animações dos personagens, dá para validar isoladamente se o Foundation Models entrega o que o produto precisa — sem depender de nenhuma tela final. É o maior risco técnico do app (é a peça mais nova e mais restrita por hardware/OS) e o mais barato de testar cedo.

### Objetivo

Responder três perguntas antes de investir na experiência completa: (1) o modelo produz sugestões de técnica corretas e no tom de cada personagem/subcultura; (2) tool calling e saída estruturada (`@Generable`/`@Guide`) funcionam de forma confiável com um inventário de itens; (3) o guardrail de conteúdo da Apple não atrapalha vocabulário legítimo da estética gótica (caveira, sangue estilizado, luto, ocultismo) — ele não pode ser desativado, então é melhor descobrir isso agora do que na reta final.

### Achados de um teste manual inicial (chamada crua, sem instructions/tool/saída estruturada)

Antes de montar a PoC estruturada, valeu a pena rodar `LanguageModelSession().respond(to:)` diretamente, só com uma pergunta em texto livre, pra ter uma primeira leitura do modelo. Três achados concretos que já mudam o desenho da seção 2 e desta PoC:

1. **Conhecimento de subcultura é real, mas desigual.** Pedido cru "how can I do a simple goth makeup" voltou um passo a passo correto e específico da estética gótica. "Gyaru" cru voltou algo genérico ("maquiagem japonesa colorida e ousada"); só ficou preciso (contorno marcado, técnica de aumentar os olhos) quando o prompt disse "gyaru clássica". "New Romantic" cru foi o pior caso: o modelo entendeu como "maquiagem romântica" genérica, sem nenhuma relação com a subcultura/movimento musical britânico do início dos anos 80 — só acertou depois de reforçar "New Romantic **80's** pop" no prompt. **Conclusão prática: não dá pra confiar só no nome da subcultura dentro do prompt. As `instructions` da sessão precisam incluir uma descrição curta de cada subcultura** (o que ela é, o que não é, referências), para não depender de o usuário/roteirista escrever a palavra-chave certa toda vez. Isso vira contexto fixo nas instructions, não algo reforçado ad-hoc a cada chamada.
2. **O modelo não respeita "use apenas estes itens" de forma confiável.** No teste com inventário limitado (`["Concealer","Black Eyeliner","Bronzer","Pink Blush","Red lipstick"]`, interpolado como array Swift dentro da pergunta), o modelo generalizou bem em alguns pontos (usou corretivo como base no rosto todo, sem base disponível) mas **ainda mencionou produtos fora da lista** (primer, pó) e, mais revelador, **forçou o uso de todos os itens mesmo quando um deles não fazia sentido pro visual** (bronzer sugerido tanto pra New Romantic quanto pra gótico, dois estilos onde bronze/glow solar não é o ponto). Isso se repetiu mesmo depois de pedir uma "breve introdução à subcultura" no prompt — ou seja, o problema não é falta de contexto cultural, é o modelo tratar o inventário como "lista pra usar por completo" em vez de "opções disponíveis, use o que fizer sentido". **Isso não se resolve só com prompt mais educado — precisa de estrutura**: um campo de saída dedicado a "itens do inventário que não foram usados e por quê" (obriga o modelo a considerar explicitamente cada item, em vez de despejar todos) e uma checagem determinística no código, comparando o texto gerado com os nomes do inventário, como rede de segurança (a seção de saída estruturada abaixo já reflete essa mudança).
3. **Latência sem streaming: 4 a 5 segundos por resposta**, mesmo pra um pedido simples de texto livre. Confirma que vale a pena usar `streamResponse()` na tela de tutorial (já previsto no escopo abaixo) em vez de esperar a resposta inteira antes de mostrar qualquer coisa — 4-5s parado sem feedback visual é tempo demais numa interação guiada por personagem.

Também vale notar: os três testes acima usaram só texto livre — nenhum usou `@Generable`/`@Guide` (saída estruturada) nem a `Tool` de consulta ao inventário. Isso significa que a base é promissora (o modelo "sabe" bastante sobre técnica de maquiagem), mas a parte de **controle/restrição** — que é justamente o que a saída estruturada e as regras explícitas nas instructions devem resolver — ainda não foi validada e é o próximo passo real desta PoC, não um "bônus".

### Critérios de sucesso

- Sugestões plausíveis e no tom certo em pelo menos ~80% de uma bateria de ~15 prompts de teste (5 por subcultura).
- **Nenhum produto fora do inventário aparece na sugestão sem estar listado no campo de "itens não utilizados"** — critério direto, motivado pelo achado nº 2 acima.
- **Itens do inventário que não fazem sentido pro visual pedido são sinalizados como não utilizados, em vez de forçados na sugestão** (ex.: bronzer num visual gótico).
- **A subcultura certa é reconhecida mesmo com o nome mais curto/ambíguo** (ex.: só "new romantic", sem precisar reforçar "anos 80"), graças ao contexto de subcultura embutido nas instructions.
- Tool calling busca corretamente o item certo no inventário mock, sem precisar reinjetar a lista inteira a cada chamada — comparar essa abordagem com a injeção direta da lista (mais simples, e foi o que funcionou nos testes manuais) e decidir qual usar na v1.
- `streamResponse()` começa a exibir texto em tempo aceitável para uma tela de tutorial — o teste manual sem streaming mediu 4-5s de espera "muda", então vale confirmar que o streaming melhora a percepção antes de travar essa decisão.
- Nenhum prompt legítimo de maquiagem gótica é bloqueado pelo guardrail; se algum for, documentar qual gatilho foi e ajustar o texto do prompt/instructions.
- O caminho de fallback (protocolo `TechniqueSuggesting` com implementação alternativa) troca de implementação sem mudar código de chamada.

### Escopo técnico — o que entra

- App/target isolado (pode ser o mesmo projeto, um target ou tela de debug separada) com UI mínima: sem arte, sem animação — texto do sistema, botões padrão, uma lista simples.
- Tela de diagnóstico checando `SystemLanguageModel.availability` e exibindo o motivo quando `.unavailable` (essencial: já foi relatado o availability retornar `.available` mesmo com o download do modelo incompleto por causa de idioma do Siri divergente do idioma do sistema — vale exibir e logar o `reason` bruto, não confiar só no booleano).
- Inventário mock (array Swift ou JSON, sem SwiftData/UI de cadastro ainda) com alguns itens por subcultura, incluindo casos de item ausente de propósito.
- `LanguageModelSession` com instructions definindo o tom de cada personagem (gótico, gyaru, new romantic) — teste se o prompt sozinho sustenta a voz ou se precisa de mais reforço a cada chamada.
- Uma `@Generable struct` de saída (ex.: passo a passo, substituições, curiosidade histórica/cultural) via `@Guide`, para validar se a saída estruturada vem consistente o suficiente para renderizar sem parsing manual de texto livre.
- Uma `Tool` simples que consulta o inventário mock, para validar o tool calling de ponta a ponta.
- Já plugar o protocolo `TechniqueSuggesting` da seção 13 aqui, com uma segunda implementação-esqueleto (`CloudFallbackSuggester` ou `StaticRulesSuggester`) — mesmo que não completa, valida que a troca de implementação não vaza para quem consome.
- Um jeito simples de registrar os resultados (print/log ou export para um arquivo) para comparar respostas entre iterações de prompt.

### Fora do escopo desta PoC

Arte e animação dos personagens, tela de câmera/edição final, interação de arrastar para a cesta, CloudKit, gamificação/GameKit, Create ML (v2) — tudo isso segue nos trilhos já descritos nas seções anteriores, sem depender do resultado desta PoC.

### Matriz de teste sugerida (mínimo 5 por subcultura)

| Subcultura | Cenário |
|---|---|
| Gótico | Item ausente (sem delineador líquido → orientar com lápis) |
| Gótico | Vocabulário sensível da estética (referência a sangue estilizado, luto, ocultismo) — checar se o guardrail interfere |
| Gótico | Inventário com item que não combina com o visual (ex.: bronzer) — checar se o modelo sinaliza como não utilizado em vez de forçar |
| Gyaru | Item presente — pedir técnica de aplicação |
| Gyaru | Pergunta de curiosidade histórica/cultural no meio do tutorial |
| New romantic | Nome da subcultura sozinho, sem reforçar "anos 80" no texto do objetivo — checar se o contexto das instructions basta pra não confundir com "maquiagem romântica" genérica |
| New romantic | Item ambíguo/nome genérico no inventário |

### Onde isso mora no código

Reaproveita diretamente a camada `Core/AI/` da arquitetura da seção 13 — a PoC não é descartável, é o começo real de `FoundationModelsSuggester.swift`. Isso significa que validar aqui já adianta trabalho de produção, em vez de ser só um protótipo joga-fora.

### Risco a confirmar antes de começar: acesso a dispositivo

Foundation Models exige iOS 26+ em hardware com Apple Intelligence (iPhone 15 Pro+). Há relatos de desenvolvedores para quem o Simulator não reporta o modelo como disponível de forma confiável — ou seja, a PoC deve partir do princípio de que vai precisar de **um iPhone físico compatível** para os testes valerem, e isso deve ser confirmado/providenciado antes de alocar tempo de desenvolvimento na PoC.

### Esforço estimado

Um dev, cerca de 3 a 5 dias — a maior parte do tempo tende a ir para iterar o texto das instructions/prompt até o tom ficar consistente, não para o código de integração em si.

## 15. Testes unitários com Swift Testing — prospecção

A seção 9 já apontava Swift Testing/XCTest + XCUITest; aqui está o detalhamento de onde aplicar Swift Testing especificamente, mapeado na arquitetura da seção 13.

### Por que Swift Testing (para a parte unitária)

Sintaxe mais enxuta que o XCTest: `@Test` no lugar do prefixo `test`, `#expect` como asserção única (mostra a expressão real que falhou, sem precisar escolher entre `XCTAssertEqual`/`XCTAssertTrue`/etc.) e `#require` para desembrulhar opcional interrompendo o teste se vier nil. Suporte nativo a `async`/`await` — importante aqui porque quase toda a camada de IA e persistência é assíncrona. Testes **parametrizados** (`@Test(arguments:)`) evitam duplicar teste por teste para cada variação de entrada. **Tags** permitem marcar e filtrar testes por categoria (ex.: separar o que roda em todo PR do que exige hardware real). E convive no mesmo target com o XCTest — o XCUITest continua sendo necessário para UI e para testes de performance (`XCTMetric`), Swift Testing não substitui isso.

### Onde aplicar, por camada

- **`Core/AI`** — o maior cuidado aqui: a resposta *real* do Foundation Models é não determinística, então não faz sentido testar unitariamente "o texto que o modelo gerou". O que dá pra testar com Swift Testing: a lógica de `TechniqueSuggesterFactory` (dado um `availability` mockado, escolhe a implementação certa), o mapeamento da saída `@Generable` para o modelo de domínio, o comportamento de erro/fallback quando a sessão lança exceção, e a conformidade do `CloudFallbackSuggester`/`StaticRulesSuggester` ao protocolo com entradas de exemplo. Testes que dependem do modelo real rodando (útil pra acompanhar a PoC da seção 14) ficam marcados com uma tag própria (ex.: `.tags(.requiresDevice)`) para não travar o CI, que não tem um iPhone 15 Pro+ disponível.
- **`Core/Persistence`** — repositórios (`MakeupInventoryRepository`, `ProgressRepository`) testados contra um `ModelConfiguration(isStoredInMemoryOnly: true)` do SwiftData: adicionar item, buscar por subcultura, marcar conquista como concluída. Cada `@Test` cria seu próprio container em memória — isolamento limpo entre testes, sem o `setUp`/`tearDown` compartilhado que o XCTest costuma exigir.
- **`Features/Cadastro`** — a lógica de "o item foi solto dentro da cesta?" (comparação de `frame`s discutida na interação de drag-and-drop) só vale a pena se estiver numa função pura, fora do gesture handler. Extraída assim, é um caso perfeito para teste parametrizado: várias combinações de posição/offset num só `@Test(arguments:)`.
- **`Features/Tutorial`** — a ViewModel testada com um mock de `TechniqueSuggesting`: verifica se o estado vai de carregando → sucesso/erro corretamente, e se o inventário é passado do jeito certo pro serviço.
- **`Features/Gamificacao`** — regras de desbloqueio de conquista (ex.: "completar 3 tutoriais do gótico desbloqueia X") são lógica pura, também ótimas para parametrização.
- **`Core/Media`** — `CameraService`/`PhotoLibraryService` são casca fina sobre AVFoundation/PhotosUI e não compensam teste unitário direto; o que vale testar é a lógica em torno (ex.: o que a tela faz com a imagem capturada), não a captura em si.

### Fora do escopo do teste unitário

Qualidade da resposta do Foundation Models real (fica com a bateria de prompts da PoC, seção 14), captura de câmera de verdade, fluxo ponta a ponta de UI (fica com XCUITest, seção 9) e testes de performance (`XCTMetric`, também XCTest).

### Recurso extra a considerar: exit tests

Desde o Swift 6.2, Swift Testing suporta **exit tests** — validam código que encerra o processo (`fatalError`, `precondition`), rodando em um processo filho. Útil se algum ponto da camada de dados usar `precondition` para invariantes (ex.: garantir que um `MakeupItem` sempre tem uma subcultura associada) e quiser testar que a violação realmente derruba o app em vez de silenciosamente continuar.

### Plano faseado

1. **Durante a PoC (seção 14):** testar a lógica de `TechniqueSuggesterFactory` e a validação da saída `@Generable` — reaproveita o trabalho da PoC diretamente.
2. **Construção da v1:** testes de repositório (SwiftData em memória), função pura do drop na cesta, ViewModels com mocks.
3. **Hardening pré-lançamento:** regras de gamificação, casos de borda, revisão de cobertura.

### Onde mora no projeto

Pasta de testes espelhando `Core/` e `Features/` (ex.: `MaquiagemAppTests/Core/AI/TechniqueSuggesterFactoryTests.swift`), rodando em todo PR — exceto os testes marcados com a tag de hardware real, que rodam manualmente antes de cada release.

---

### Fontes consultadas

- [Exploring the Foundation Models framework — Create with Swift](https://www.createwithswift.com/exploring-the-foundation-models-framework/)
- [WWDC 2026 — Apple Just Opened the Foundation Models Framework to Any LLM Provider](https://dev.to/arshtechpro/wwdc-2026-apple-just-opened-the-foundation-models-framework-to-any-llm-provider-5ejn)
- [Bring an LLM provider to the Foundation Models framework — WWDC26, Apple Developer](https://developer.apple.com/videos/play/wwdc2026/339/)
- [How to get Apple Intelligence — Apple Support](https://support.apple.com/en-us/121115)
- [SwiftData vs Core Data — 2026 comparisons (Medium/theswiftk.it.com)](https://theswiftk.it.com/blog/swiftdata-vs-core-data-swiftui)
- [How to fix guardRailViolationError with Foundation Models on Xcode 26](https://joschua.io/posts/2025/08/23/guardrail-error-xcode-26/)
- [Foundation models not detectable in Xcode simulator — Apple Developer Forums](https://developer.apple.com/forums/thread/815397)
- [Swift Testing explained with code examples — SwiftLee](https://www.avanderlee.com/swift-testing/modern-unit-test/)
