# Guia de Contribuição

Este documento define como o time trabalha no repositório do app: como escrever commits, nomear branches e abrir PRs. O objetivo não é burocracia — é deixar o histórico do Git fácil de ler por qualquer pessoa do time, inclusive quem entrar depois.

## 1. Padrão de commits (Conventional Commits)

Toda mensagem de commit segue o formato:

```
tipo(escopo): descrição curta, no imperativo
```

**Tipos:**

| Tipo | Quando usar | Exemplo |
|---|---|---|
| `feat` | uma funcionalidade nova | `feat(cadastro): adiciona drag and drop dos itens para a cesta` |
| `fix` | correção de bug | `fix(camera): corrige crash ao negar permissão de câmera` |
| `refactor` | muda o código sem mudar o comportamento pra quem usa | `refactor(tutorial): extrai lógica de sugestão para protocolo TechniqueSuggesting` |
| `test` | adiciona ou ajusta teste | `test(inventario): cobre validação de item duplicado` |
| `docs` | documentação (README, comentários grandes, docs de arquitetura) | `docs(arquitetura): atualiza fluxo de cadastro para seleção por catálogo` |
| `chore` | manutenção que não é funcionalidade (CI, dependências, organização de pastas) | `chore: configura Swift Testing no target de testes` |
| `style` | formatação, indentação, sem mudar lógica | `style(cadastro): aplica SwiftFormat no CadastroView` |
| `perf` | melhoria de performance | `perf(camera): reduz tempo de renderização do ImageRenderer` |

**Escopo:** use o nome da feature ou área que o commit tocou, seguindo as pastas do projeto: `salao`, `cadastro`, `tutorial`, `camera`, `edicao`, `compartilhamento`, `gamificacao`, `poc-ia`, `arquitetura`, `design`. Isso facilita filtrar o histórico de uma feature específica (`git log --grep="(cadastro)"`).

**Descrição:** curta, no imperativo ("adiciona", "corrige", "remove" — não "adicionado" ou "adicionando"), sem ponto final.

Se o commit precisar de mais contexto, adicione um corpo depois de uma linha em branco:

```
refactor(tutorial): migra TutorialViewModel de ObservableObject para @Observable

Reduz boilerplate e evita re-render da view inteira quando só uma
propriedade muda. Ver documento-arquitetura.md seção 2.3.
```

## 2. Nomes de branch

```
feature/<escopo>-<resumo>     ex.: feature/cadastro-drag-drop
fix/<escopo>-<resumo>         ex.: fix/camera-permissao
poc/<nome>                    ex.: poc/foundation-models
chore/<resumo>                ex.: chore/configura-swift-testing
```

A PoC do Foundation Models, por ser um trabalho experimental (código sem garantia de já funcionar, só validado em device físico), fica isolada na sua própria branch por mais tempo — sem pressa de integrar ao branch principal antes de estar validada.

## 3. Pull Requests

- **PRs pequenos e focados em uma coisa só.** Um PR por feature ou por correção — não misture cadastro, tutorial e câmera no mesmo PR. Fica mais fácil revisar e mais fácil reverter se algo quebrar.
- **Descrição do PR:** o que mudou e por quê (o "porquê" importa mais que o "o quê", que já está no diff). Se a mudança envolve uma decisão de arquitetura, referencie o documento (`documento-arquitetura.md`) ou a seção do levantamento técnico.
- **Antes de abrir o PR, confira:**
  - [ ] O projeto compila sem warnings novos
  - [ ] Os testes (Swift Testing) passam
  - [ ] Se mexeu em `Core/AI`, testou com um mock — não precisa de device físico pra rodar os testes
  - [ ] Se mexeu em algo visual, anexou print ou GIF do resultado

## 4. Versionamento

Enquanto o app não está publicado, não é necessário seguir versionamento semântico (`MAJOR.MINOR.PATCH`) à risca — mas ao aproximar do lançamento da v1, vale adotar tags de versão (`v1.0.0`) alinhadas com o Conventional Commits, que permite gerar changelog automático a partir do histórico (`feat` vira MINOR, `fix` vira PATCH, mudança incompatível vira MAJOR).
