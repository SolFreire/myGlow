# Assets do myGlow — nomes esperados pelo código

O código já procura estes nomes no `Assets.xcassets`. Enquanto um asset não existe,
a tela desenha um placeholder tracejado no lugar (`ArteView`, em `Core/DesignSystem/Arte.swift`);
assim que o arquivo entra no catálogo com o nome exato, a arte aparece — **sem mudar uma linha de código**.

Três regras que evitam retrabalho:

1. **O nome do image set é o que vale**, não o nome do arquivo PNG solto.
2. **Não marque "Provides Namespace"** nas pastas do catálogo. Se marcar, o nome em código vira
   `Pasta/nome` e nada é encontrado.
3. **Diferencia maiúscula de minúscula.** Repare que `card-newRomantic` é camelCase (vem do
   `rawValue` da subcultura), enquanto todo o resto é kebab-case.

Os nomes das **ilustrações de etapa** (seção 5) são os únicos editáveis sem tocar em Swift:
eles vivem no campo `ilustracoes` dos JSONs em `myGlow/Resources/Roteiros/`. Se o design preferir
outra nomenclatura, muda-se o JSON.


## Duas armadilhas que derrubam o app

Estas duas não dão erro de compilação nem imagem borrada: **derrubam o app** na primeira tela que
usa o asset. Vale conferir na hora de subir arte.

**1. Slot de escala declarado e vazio.** Se o image set tiver a caixinha 2x ou 3x *declarada* mas sem
arquivo, o UIKit estoura ao carregar. Se você só tem uma escala, apague as outras caixinhas em vez de
deixá-las vazias. (A caixinha 1x vazia é segura — não existe mais aparelho @1x, então o sistema nunca
pede por ela.)

**2. Mesmo nome para uma cor e uma imagem.** Pedir uma *imagem* pelo nome de um *Color Set* derruba o
app dentro do UIKit. O código agora barra isso antes de chegar lá, mas o asset fica invisível na
tela. Se algo sumiu sem explicação, confira se o nome não está sendo usado por um Color Set.


## Formato de exportação

O Xcode converte SVG para vetor do CoreGraphics e **descarta em silêncio** o que não sabe
representar: sombra, blur, blend mode, máscara com imagem, textura, pattern. Por isso o formato
muda conforme o tipo de arte.

| Grupo | Formato | Por quê |
|---|---|---|
| `item-*`, `icone-maleta`, `icone-album` | **SVG** | Vetor chapado; escala sem borrar e o arquivo é pequeno |
| `maleta` | SVG se for chapada, PNG se tiver sombra ou textura | — |
| `personagem-*`, `card-*`, ilustrações de etapa | **PNG @2x e @3x** | Têm sombreado, gradiente e textura que o SVG perderia |
| `moldura-*` | **PNG 1080×1080, escala única, centro transparente** | É o tamanho exato em que o `MolduraRenderer` compõe a foto |

**Exportando SVG do Figma:** ligue *Outline text* e *Simplify stroke*, desligue *Include "id" attribute*.
Se a camada tiver efeito aplicado (drop shadow, blur, background blur), o SVG sai sem ele — exporte
essa camada como PNG.

**No Xcode, depois de arrastar o SVG:** no inspetor do image set, marque **Preserve Vector Data** e
mude **Scales** para **Single Scale**. Sem isso o Xcode rasteriza no tamanho original e o ícone
borra quando cresce.

### Sobre @2x e @3x

O iOS mede tudo em **pontos**, não em pixels. Cada ponto vale 2 pixels num aparelho @2x (iPads,
iPhones da linha simples) ou 3 pixels num @3x (iPhones Pro). Uma arte de 110 pontos de altura
precisa então de 220px para ficar nítida no @2x e 330px no @3x — exportar só 1x faz o sistema
esticar e borrar.

No Figma: desenhe em 1x e marque `2x` e `3x` no painel de export. No Xcode, cada image set tem as
caixinhas 1x/2x/3x; a de 1x pode ficar vazia. **SVG não precisa disso** — é vetor, vai em escala única.

Tamanhos tirados direto do código, ou seja, a medida real em que cada arte é desenhada:

| Asset | Pontos | @2x | @3x |
|---|---|---|---|
| `card-*` | 212 × 110 | 424 × 220 | 636 × 330 |
| `personagem-edna` | 320 × 380 | 640 × 760 | 960 × 1140 |
| `personagem-*` (tutorial) | 320 × 300 | 640 × 600 | 960 × 900 |
| ilustrações de etapa | 320 × 300 | 640 × 600 | 960 × 900 |
| `item-*` | 72 × 40 | SVG, escala única | — |
| `icone-maleta`, `icone-album` | 44 × 44 | SVG, escala única | — |
| `maleta` | 222 × 56 | 444 × 112 | 666 × 168 |
| `moldura-*` | — | — | **1080 × 1080 na caixinha 1x** |

A moldura é a exceção: ela não vai para a tela, vai para dentro da foto salva, que o app compõe num
quadro fixo de 1080×1080 pixels.

## 0. Tela Inicial — a porta do salão, aparece em toda entrada

| Asset | @2x | @3x |
|---|---|---|
| `fundo-tela-inicial` | 1704 × 786 | 2556 × 1179 |

PNG (tem degradê, xadrez e sombra que o SVG perderia). **Desenhe com ~40pt de sangria de cada lado**:
a arte cobre a tela inteira e o excedente das laterais é cortado, para a porta e o letreiro ficarem
sempre centralizados em qualquer proporção de tela.

O botão "Jogar" **não** entra no PNG — é botão de verdade, para responder ao toque e ao VoiceOver.
O letreiro "myGlow" pode ficar dentro do fundo, a não ser que as lâmpadas vão animar depois.

## 1. Salão e personagens — desbloqueia a tela inicial

| Asset | Onde aparece | Formato sugerido |
|---|---|---|
| `card-gotica` | Card da Lucy no Salão | retrato, ~2:3 |
| `card-gyaru` | Card da Sana no Salão | retrato, ~2:3 |
| `card-newRomantic` | Card da Cindy no Salão | retrato, ~2:3 |
| `personagem-edna` | Fluxo de primeiro uso | corpo inteiro, retrato |
| `personagem-gotica` | Tutorial da Lucy (fallback da etapa) | corpo inteiro, retrato |
| `personagem-gyaru` | Tutorial da Sana (fallback da etapa) | corpo inteiro, retrato |
| `personagem-newRomantic` | Tutorial da Cindy (fallback da etapa) | corpo inteiro, retrato |

## 2. Ícones e maleta — desbloqueia o cabeçalho do Salão e o Cadastro

| Asset | Onde aparece |
|---|---|
| `icone-maleta` | Botão "Minha maleta" no Salão |
| `icone-album` | Botão "Meu álbum" no Salão |
| `maleta` | A maleta grande da tela de Cadastro (alvo do arraste) |

## 3. Molduras da foto final

| Asset | Onde aparece | Formato |
|---|---|---|
| `moldura-gotica` | Composição da foto salva | quadrado 1080×1080, PNG com transparência no centro |
| `moldura-gyaru` | Composição da foto salva | quadrado 1080×1080, PNG com transparência no centro |
| `moldura-newRomantic` | Composição da foto salva | quadrado 1080×1080, PNG com transparência no centro |

Sem a moldura, a foto sai com uma borda na cor da subcultura e a assinatura `myGlow · <Subcultura>`.


## 4. Catálogo de maquiagem — 27 itens, desbloqueia o Cadastro

Ícone quadrado, ~200×200, fundo transparente.

| Asset | Item |
|---|---|
| `item-base` | Base |
| `item-corretivo` | Corretivo |
| `item-po` | Pó |
| `item-blush` | Blush |
| `item-contorno` | Contorno |
| `item-iluminador` | Iluminador |
| `item-clown` | Clown |
| `item-pancake` | Pancake |
| `item-sombra-branca` | Sombra branca |
| `item-sombra-preta` | Sombra preta |
| `item-sombra-laranja` | Sombra laranja |
| `item-sombra-azul` | Sombra azul |
| `item-sombra-roxa` | Sombra roxa |
| `item-sombra-magenta` | Sombra magenta |
| `item-sombra-amarela` | Sombra amarela |
| `item-sombra-verde` | Sombra verde |
| `item-caneta-delineadora` | Caneta delineadora |
| `item-lapis-preto` | Lapis preto |
| `item-lapis-branco` | Lapis branco |
| `item-mascara-cilios` | Mascara cilios |
| `item-cilios-posticos` | Cilios posticos |
| `item-lapis-sobrancelha` | Lapis sobrancelha |
| `item-batom` | Batom |
| `item-gloss` | Gloss |
| `item-lapis-labial` | Lapis labial |

## 5. Ilustrações das etapas do tutorial

Editáveis pelo campo `ilustracoes` de cada etapa nos JSONs de roteiro.


### Lucy — `gotica.json`

| Etapa | Assets |
|---|---|
| Olá, Lucy | `gotica-ola-1` |
| Base (Clown + Pancake) | `gotica-base-1`, `gotica-base-2` |
| Contorno | `gotica-contorno-1` |
| Sombra | `gotica-sombra-1` |
| Delineado | `gotica-delineado-1`, `gotica-delineado-2` |
| Batom | `gotica-batom-1` |
| Gloss | `gotica-gloss-1` |
| Fechamento | `gotica-fechamento-1` |

### Sana — `gyaru.json`

| Etapa | Assets |
|---|---|
| Olá, Sana | `gyaru-ola-1`, `gyaru-ola-2` |
| Pele | `gyaru-pele-1`, `gyaru-pele-2`, `gyaru-pele-3` |
| Contorno | `gyaru-contorno-1`, `gyaru-contorno-2`, `gyaru-contorno-3` |
| Sombra | `gyaru-sombra-1`, `gyaru-sombra-2` |
| Delineado | `gyaru-delineado-1`, `gyaru-delineado-2` |
| Cílios | `gyaru-cilios-1`, `gyaru-cilios-2` |
| Blush | `gyaru-blush-1` |
| Batom | `gyaru-batom-1`, `gyaru-batom-2` |
| Fechamento | `gyaru-fechamento-1` |

### Cindy — `new-romantic.json`

| Etapa | Assets |
|---|---|
| Oi, Cindy | `new-romantic-oi-1` |
| Base | `new-romantic-base-1`, `new-romantic-base-2` |
| Blush | `new-romantic-blush-1`, `new-romantic-blush-2` |
| Sombra | `new-romantic-sombra-1` |
| Delineado | `new-romantic-delineado-1` |
| Boca | `new-romantic-boca-1` |
| Detalhe | `new-romantic-detalhe-1` |
| Fechamento | `new-romantic-fechamento-1` |
