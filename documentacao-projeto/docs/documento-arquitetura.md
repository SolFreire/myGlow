# Documento de Arquitetura — App de Maquiagem Gamificado (iOS)

## 1. Contexto e requisitos

### 1.1 Visão geral

**Challenge Statement:** como ajudar alguém a aprender e se expressar através da maquiagem de forma lúdica e culturalmente rica, mesmo quando não tem todos os produtos "ideais" à disposição ou não conhece técnicas alternativas para os que já possui?

**Challenge Response:** um app iOS gameficado e personalizado sobre maquiagem como forma de expressão, ambientado num salão virtual e organizado em três subculturas — gótica, gyaru e new romantic. O usuário cadastra as maquiagens que já possui e escolhe uma experiência para seguir, onde um personagem guia o passo a passo da própria maquiagem daquela subcultura enquanto conta curiosidades históricas e culturais sobre ela. Ao longo da elaboração, o Foundation Models usa o inventário cadastrado para sugerir técnicas alternativas quando falta algum item (por exemplo, orientar como recriar o efeito de um delineador líquido usando lápis). Ao final, o usuário pode, opcionalmente, tirar uma foto e salvá-la localmente no dispositivo.

### 1.2 Principais requisitos

- Persistir localmente o inventário de maquiagens cadastrado pelo usuário e recuperá-lo entre sessões, sem depender de conexão com a internet.
- Gerar sugestões de técnica personalizadas a partir do inventário cadastrado, preservando a privacidade do usuário — a IA deve rodar on-device sempre que o hardware permitir.
- Funcionar de forma consistente em dispositivos que não suportam Apple Intelligence, com uma alternativa (fallback) para a funcionalidade de sugestão em vez de travar ou remover a etapa do tutorial.
- Suportar três trilhas de conteúdo/personagem (gótico, gyaru, new romantic) de forma extensível, permitindo adicionar uma nova subcultura sem redesenhar a arquitetura.
- Capturar e salvar a foto final localmente, respeitando as permissões do sistema (câmera e fotos).
- Manter a lógica de sugestão e de persistência isolada da interface, para permitir testes automatizados sem depender de hardware específico em todo teste.

## 2. Arquitetura adotada

### 2.1 Padrão/arquitetura

A arquitetura adotada é **MVVM (Model-View-ViewModel)** com o framework **Observation** do Swift (`@Observable`), organizada por *feature* (uma pasta por tela/fluxo — Salão, Cadastro, Tutorial, Câmera) em vez de por tipo de arquivo.

Essa combinação é adequada para os requisitos acima por alguns motivos concretos:

- **Aderência nativa ao SwiftUI.** MVVM com `@Observable` é o padrão que a própria Apple recomenda para SwiftUI: a View observa o estado da ViewModel e se atualiza automaticamente quando ele muda, sem código de sincronização manual.
- **Isolamento testável da IA e da persistência.** A camada de domínio (a sugestão de técnica e o acesso ao inventário) fica atrás de protocolos (`TechniqueSuggesting`, `MakeupInventoryRepository`). Isso atende diretamente ao requisito de manter a lógica testável sem depender de hardware: os testes usam implementações falsas desses protocolos, e só a implementação real (`FoundationModelsSuggester`) precisa rodar num iPhone compatível.
- **Suporte nativo ao requisito de fallback.** Como a escolha de qual implementação usar (`FoundationModelsSuggester` on-device ou `StaticRulesSuggester`) está isolada numa fábrica (`TechniqueSuggesterFactory`) por trás do protocolo, a ViewModel do Tutorial nunca precisa saber qual das duas está ativa — o fallback é uma troca de implementação, não uma ramificação espalhada pela UI.
- **Proporcional ao tamanho e à fase do projeto.** Alternativas como o TCA (The Composable Architecture) são mais rigorosas para testar efeitos assíncronos de forma determinística, mas pedem mais ceremônia (reducers, actions, macros) do que o formato atual do app — uma jornada majoritariamente linear — justifica. MVVM com protocolos entrega a maior parte do benefício de testabilidade do TCA sem essa sobrecarga, e a decisão pode ser revisitada caso o app cresça em estado compartilhado entre features.

### 2.2 Diagrama da arquitetura

![Diagrama da arquitetura: View (SwiftUI) se comunica bidirecionalmente com ViewModel (@Observable); ViewModel chama protocolos de domínio (MakeupInventoryRepository, TechniqueSuggesting) via async/await; os protocolos são implementados por SwiftDataInventoryRepository, FoundationModelsSuggester e seu fallback StaticRulesSuggester; essas implementações conversam com SwiftData, a Apple Intelligence e a Câmera/Rolo de fotos do sistema.](arquitetura.png)

O diagrama lê-se de cima para baixo: a **View** (SwiftUI) troca ações do usuário e estado com a **ViewModel** correspondente (`@Observable`); a ViewModel nunca fala diretamente com SwiftData ou com o Foundation Models — ela chama um **protocolo de domínio** (`MakeupInventoryRepository` ou `TechniqueSuggesting`); cada protocolo tem uma **implementação concreta** que conversa com o **framework do sistema** de fato (SwiftData, Apple Intelligence via `LanguageModelSession`, ou AVFoundation/PhotosUI). O único ponto onde duas features se cruzam é a `TutorialViewModel` lendo o mesmo repositório de inventário que a `CadastroViewModel` escreve — é assim que a sugestão de técnica "enxerga" o que foi cadastrado.

## 3. Fluxo de dados

O fluxo mais representativo do app é o que vai do cadastro de um item até a sugestão de técnica aparecer na tela do Tutorial:

1. Na tela de **Cadastro**, o usuário não digita o nome do item — ele **seleciona** um item numa lista ilustrada de opções pré-definidas (catálogo curado pelo time de design, com ícone/ilustração por item). A ação de seleção (hoje desenhada como arrastar o item ilustrado até a cesta da categoria correspondente) já chega pronta e válida à View, que a repassa para a `CadastroViewModel` através de uma chamada direta de método (ex.: `adicionarItem(nome:)`, onde `nome` é o identificador do item escolhido no catálogo, não um texto livre).
2. Como a entrada vem de uma seleção fechada, não de digitação, a `CadastroViewModel` **não precisa validar formato de texto** (campo vazio, caracteres inválidos etc.) — esse tratamento de erro simplesmente não existe nesse fluxo. A única validação que ainda faz sentido é de duplicidade (evitar cadastrar o mesmo item ilustrado duas vezes), e mesmo essa é opcional dependendo de como o design tratar o item já cadastrado na tela. A ViewModel chama o `MakeupInventoryRepository` (protocolo) de forma assíncrona.
3. A implementação real (`SwiftDataInventoryRepository`) persiste o item como um `@Model` do SwiftData. A lista de itens exibida na tela de Cadastro é atualizada automaticamente, sem código extra de sincronização.
4. Quando o usuário entra na trilha do **Tutorial** de uma subcultura, a `TutorialViewModel` busca o inventário atual através do mesmo `MakeupInventoryRepository`.
5. Ao chegar numa etapa que precisa de orientação, a `TutorialViewModel` chama `TechniqueSuggesting.suggestTechnique(for:inventory:)`, passando a etapa atual e o inventário lido no passo anterior.
6. A implementação escolhida pela `TechniqueSuggesterFactory` — `FoundationModelsSuggester`, se o dispositivo suportar Apple Intelligence, ou `StaticRulesSuggester`, caso contrário — processa o pedido. No caminho on-device, isso envolve montar uma `LanguageModelSession` com as instruções do personagem, permitir que o modelo consulte o inventário através de uma *tool* própria, e pedir uma saída estruturada (não texto livre) descrevendo passo a passo, substituições e uma curiosidade cultural.
7. O resultado chega de volta à `TutorialViewModel` de forma assíncrona (`async`/`await`); qualquer erro (por exemplo, o guardrail de conteúdo da Apple rejeitando o pedido) é capturado e tratado como um estado de erro, não deixado subir para a View.
8. A `TutorialViewModel` atualiza suas propriedades observáveis (`@Observable`) com o resultado (ou o erro). A View do Tutorial, que observa essas propriedades, se redesenha automaticamente exibindo o passo a passo, as substituições sugeridas e a curiosidade — sem callback manual entre ViewModel e View.
9. Ao final da experiência, a tela de **Câmera** segue um fluxo paralelo mais simples: captura via `CameraService` (AVFoundation/PhotosUI) e salvamento local via `PhotoLibraryService`, sem envolver a camada de IA.

## 4. Tecnologias e frameworks

| Tecnologia | Papel no projeto |
|---|---|
| **Swift + SwiftUI** | Linguagem e framework de UI; base de toda a camada de View e a integração nativa com o restante da lista. |
| **Observation (`@Observable`)** | Sustenta a comunicação View ↔ ViewModel sem boilerplate — a View reage a mudanças de estado automaticamente. |
| **SwiftData** | Persistência local do inventário de maquiagens e do progresso do usuário, sem exigir servidor próprio. |
| **Foundation Models framework** | IA on-device que gera as sugestões de técnica a partir do inventário cadastrado, com saída estruturada (`@Generable`/`@Guide`) e capacidade de consultar o inventário via *tool calling*. |
| **AVFoundation / PhotosUI** | Captura da foto final e salvamento no rolo da câmera do dispositivo. |
| **Swift Testing** | Testes unitários da lógica de domínio (fábrica de sugestão, repositórios, regras), isolada de UI e de hardware específico. |

## 5. Comunicação entre componentes

- **View ↔ ViewModel:** via **Observation** (`@Observable`). A View chama métodos da ViewModel diretamente em resposta a ações do usuário (toques, texto digitado); a ViewModel expõe propriedades observáveis, e o SwiftUI redesenha automaticamente qualquer View que dependa de uma propriedade que mudou — não há delegates nem closures manuais nesse sentido.
- **ViewModel → dados e serviços:** sempre através de um **protocolo** (`MakeupInventoryRepository`, `TechniqueSuggesting`), nunca contra a implementação concreta diretamente. A implementação é injetada no `init` da ViewModel (injeção de dependência simples, sem framework de DI).
- **Operações assíncronas:** tratadas com **`async`/`await`**. A ViewModel chama a operação dentro de uma `Task`, aguarda o resultado e atualiza suas próprias propriedades `@Observable` quando ele chega — é essa atualização de propriedade, e não um callback explícito, que faz a interface reagir.
- **Dentro do Foundation Models:** a *tool* de consulta ao inventário é chamada pelo próprio framework durante a geração da resposta, de forma transparente para a ViewModel — ela só percebe o resultado final (`TechniqueSuggestion`) ou um erro.

## 6. Pontos em aberto

- **Escopo da edição/compartilhamento da foto final.** A visão mais ampla do produto incluía editar a foto com elementos gráficos da subcultura e compartilhá-la; esta versão do escopo cita apenas capturar e salvar localmente. Vale confirmar se edição/compartilhamento entram nesta primeira versão ou ficam para uma iteração seguinte.
- **Estratégia de fallback quando o dispositivo não suporta Apple Intelligence.** Hoje o `StaticRulesSuggester` é um esqueleto com conteúdo fixo de exemplo. Decidir entre investir em conteúdo estático editorial de verdade ou usar um provedor de IA em nuvem como fallback (novidade do WWDC26 que abriu o Foundation Models framework a provedores de terceiros) — essa segunda opção exige um pequeno backend próprio para guardar a chave de API com segurança.
- **Sincronização entre dispositivos.** Ainda não decidido se o inventário e o progresso ficam só no dispositivo (SwiftData local) ou se será adicionada sincronização via CloudKit.
- **Risco do guardrail de conteúdo da Apple sobre o vocabulário da estética gótica** (referências a caveira, sangue estilizado, luto, ocultismo) — precisa ser validado com uma bateria de prompts de teste antes de travar esse fluxo como definitivo, já que o guardrail não pode ser desativado.
- **Acesso a dispositivo físico compatível** (iPhone 15 Pro ou mais recente, com Apple Intelligence habilitada) para testar a integração real com o Foundation Models — o Simulator do Xcode não relata a disponibilidade do modelo de forma confiável, então os testes de verdade dependem de hardware específico.
- **Extensibilidade do cadastro para reconhecimento por foto.** Uma eventual segunda versão pretende usar Create ML para sugerir automaticamente a categoria de um item a partir de uma foto — vale já deixar um ponto de extensão simples no fluxo de cadastro atual para não precisar redesenhar a tela depois.
