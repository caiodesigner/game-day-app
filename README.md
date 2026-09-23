# Block Puzzle

Aplicativo Android em Flutter, inspirado no gênero Block Puzzle: tabuleiro 8×8,
três peças por rodada, pontuação e recorde local. O jogo será offline, sem login,
anúncios ou WebView. O plano original está em
[plano_de_desenvolvimento_block_puzzle_game.md](plano_de_desenvolvimento_block_puzzle_game.md).

## Ambiente de desenvolvimento

No terminal Bash, a partir da raiz:

```bash
source scripts/env.sh
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

O Flutter fica em `.tools/flutter`; Dart vem junto com ele. Os caches Pub e
Gradle ficam em `.tools/` e não devem ser versionados. O SDK Android existente
fica em `~/Android/Sdk`. O script configura apenas a sessão atual, sem alterar
o perfil global do terminal. Se necessário, defina `ANDROID_HOME` e `JAVA_HOME`
antes de carregá-lo. A configuração do VS Code corresponde a esta máquina Linux.

Preparação validada com Flutter 3.47.5, Dart 3.13.4 e compilação de APK debug
ARM64. Consulte [o registro do ambiente](docs/ambiente.md) para versões e resultados.

Abra esta pasta no VS Code. As extensões recomendadas estão em
`.vscode/extensions.json`; as configurações de execução em `.vscode/launch.json`.
Abra um novo terminal integrado após mudanças de configuração.

Prefira um celular físico com depuração USB para economizar memória:

```bash
source scripts/env.sh
flutter devices
flutter run
```

Autorize a conexão USB na tela do celular. Use debug durante o desenvolvimento
para hot reload; `flutter run --release` serve para avaliar a versão otimizada.

```bash
flutter build apk --split-per-abi
```

Saída ARM64: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
A assinatura de distribuição será configurada antes de publicar.
Os downloads iniciais exigem internet; isso não altera o requisito de jogo offline.

## Gerar APK com versão e data

Na raiz do projeto, execute no Bash:

```bash
source scripts/env.sh

APP_VERSION="1.0.0"
APP_BUILD_NUMBER="1"
APK_DATE="$(date +%d-%m-%y)"
APK_DIR="build/app/outputs/flutter-apk"
APK_NAME="bloc-puzzle-v-${APP_VERSION}-${APK_DATE}.apk"

flutter build apk --release \
  --build-name="$APP_VERSION" \
  --build-number="$APP_BUILD_NUMBER" &&
  cp "$APK_DIR/app-release.apk" "$APK_DIR/$APK_NAME"
```

Esse comando gera um APK universal para Android (ARM32, ARM64 e x86_64).
`APP_VERSION` define a versão interna exibida pelo aplicativo; `APP_BUILD_NUMBER`
define o código inteiro da versão no Android. Aumente o código a cada nova
distribuição e ajuste a versão conforme a atualização. Esses parâmetros valem
para essa compilação e não alteram a versão padrão do `pubspec.yaml`.

A data usa o relógio local no formato `dd-mm-aa`. Por exemplo, a versão `1.0.0`
gerada em 22/09/2026 fica em:

```text
build/app/outputs/flutter-apk/bloc-puzzle-v-1.0.0-22-09-26.apk
```

A cópia com nome personalizado só é feita se a compilação terminar com sucesso.
Gerar novamente a mesma versão na mesma data substitui o arquivo anterior.
O APK mantém a assinatura de desenvolvimento configurada no projeto; a assinatura
para publicação na loja ainda precisa ser configurada.

## Etapas

1. **Preparação:** Flutter, ferramentas Android, editor e validação de build.
2. **Fase 1 — lógica (implementada):** `BoardLogic` em Dart puro; matriz 8×8; inserção válida e
   atômica; limpeza simultânea de linhas/colunas; pontuação e testes unitários.
3. **Fase 2 — interação (implementada):** tabuleiro responsivo, dock com três peças,
   arrastar e soltar, prévia de encaixe e reposição por rodada.
4. **Fase 3 — estado e persistência (implementada):** detectar ausência de movimentos entre
   todas as peças restantes; salvar recorde com `shared_preferences`.
5. **Fase 4 — polimento (implementada):** animações, áudio local com `audioplayers`, reinício,
   diálogo de game over e testes em celular.

Provider conecta estado e interface; a lógica do tabuleiro
permanece independente de widgets. As demais dependências de jogo serão adicionadas
nas respectivas fases.

## Lógica do jogo — Fase 1

O código em `lib/game/` é Dart puro, sem dependências de widgets ou serviços.
`Piece` contém offsets imutáveis e um ID de cor positivo. `Pieces` oferece
15 formatos: quadrados 1×1, 2×2 e 3×3; linhas horizontais e verticais de 2 a 5;
L, J, T e Z em orientações fixas. Geração de rodadas ficará para a Fase 2.

```dart
final board = BoardLogic();
final fits = board.canPlace(Pieces.square2, x: 3, y: 2);
final move = board.tryPlace(Pieces.square2, x: 3, y: 2);
// move == null: posição inválida, sem alterar tabuleiro ou pontuação.
// move != null: pontos e índices das linhas/colunas eliminadas.
```

Importe `package:block_puzzle/game/board_logic.dart` e
`package:block_puzzle/game/piece.dart`. As coordenadas começam em zero:
`x` é coluna, `y` é linha, e a matriz é acessada como `board.cells[y][x]`.
O getter retorna uma cópia imutável; `0` representa vazio. `board.score` acumula
os pontos e `board.reset()` inicia um tabuleiro vazio com pontuação zero.

Cada bloco colocado vale 1 ponto. O bônus por `n` linhas/colunas no mesmo
movimento é `10 × n × (n + 1) ÷ 2`: 10, 30, 60, 100… A fórmula generaliza
os exemplos do plano. Uma linha e uma coluna cruzadas contam como duas linhas;
ambas são detectadas antes da limpeza. Blocos restantes permanecem na posição,
sem gravidade. A limpeza ocorre dentro de `tryPlace`, evitando pontuação dupla.

Execute `flutter test --coverage` para validar as regras e gerar `coverage/lcov.info`.
Os testes cobrem limites, sobreposição, encaixes com espaços vazios, cores,
limpeza simultânea, combos, imutabilidade, catálogo e reinício.

## Interface e rodadas — Fase 2

`GameController` gerencia a pontuação, as três posições do dock e a rodada via
Provider. Cada peça tem identidade própria: jogadas repetidas ou dados de uma
partida reiniciada são rejeitados. Uma nova rodada é gerada somente após usar
as três peças. Formatos e cores são aleatórios; repetições são permitidas.

A dificuldade começa no nível 1 e aumenta a cada 500 pontos: nível 2 aos
500, nível 3 aos 1.000 e assim por diante. Cada nível aumenta a chance de
sortear peças maiores nas próximas rodadas, mantendo todos os formatos
disponíveis e preservando as peças já entregues. O nível aparece ao lado da
rodada e volta a 1 ao reiniciar a partida.

`GameScreen` exibe o tabuleiro com `GridView.builder`, `DragTarget` nas células
e `Draggable` no dock. A peça aumenta para a escala do tabuleiro ao arrastar;
a peça fica centralizada horizontalmente e inteiramente acima do dedo, com
50 pontos lógicos de separação. A prévia e o encaixe seguem a posição visual
da peça, não a posição do dedo. A prévia usa a cor da peça com 38% de opacidade
quando cabe e vermelha quando não cabe. Soltar fora ou sobre uma posição inválida
mantém a peça no dock. Apenas uma peça pode ser arrastada por vez.

A pontuação atualiza após cada jogada, incluindo limpezas e combos. O botão
de reinício limpa a partida e gera três novas peças. O layout adapta o tabuleiro
à tela; em janelas baixas, a página permite rolagem.

Os testes de widgets simulam arrastar e soltar, prévia, rejeição, reposição de
rodada e reinício, além de verificar layouts de celular, paisagem e tablet.
Para testar no celular, execute `source scripts/env.sh` e `flutter run`.

## Game over e recorde — Fase 3

Após cada jogada válida, incluindo a limpeza e a reposição do dock, o jogo
verifica todas as posições para todas as peças restantes. Se nenhuma couber,
a tela de fim de jogo mostra pontuação e recorde e oferece “Jogar novamente”.
A partida encerrada bloqueia novas jogadas. Reiniciar preserva o recorde.

O recorde é carregado e salvo localmente usando `SharedPreferencesAsync`, pela
chave `block_puzzle.high_score`. Ele é atualizado durante a partida, sem esperar
pelo game over. A gravação é sequencial para evitar que operações assíncronas
antigas substituam um recorde maior. Falhas de armazenamento exibem um aviso,
sem interromper a partida; a próxima jogada ou reinício tenta salvar novamente.
Somente o recorde é persistido: ao reabrir o app, a partida começa do zero.

Os testes incluem movimentos restantes, peças recém-geradas, espaços liberados
por limpeza, carregamento tardio, falhas de armazenamento, reabertura simulada,
integração com o backend de teste de SharedPreferences e a tela de fim de jogo.

Para validar a persistência no aparelho, faça pontos, feche o app e abra novamente:
a pontuação deve começar em zero, mantendo o recorde. Como esta fase adiciona
um plugin nativo, encerre a execução anterior e execute `flutter run` novamente;
apenas hot reload não instala o plugin Android.


Os blocos são desenhados com facetas diagonais, bordas chanfradas e brilho no
canto superior esquerdo, seguindo a estética de joia do ícone. O acabamento
é vetorial e compartilhado entre tabuleiro, dock, prévia e arrasto.

## Efeitos e polimento — Fase 4

As linhas eliminadas encolhem e desaparecem em 340 ms, mantendo as cores
originais inclusive nos cruzamentos. A interface mostra pontos da última jogada
e o multiplicador de combo. Durante a transição, novos arrastos ficam bloqueados;
as regras e a pontuação são aplicadas apenas uma vez.

Os efeitos de encaixe, limpeza e fim de jogo usam arquivos WAV originais em
`assets/audio/`, reproduzidos por `audioplayers`. O botão de volume silencia ou
reativa os sons; a escolha permanece ao reiniciar partidas na mesma sessão
(não é persistida ao fechar o app). O áudio para quando o app perde o foco e os
recursos são liberados ao fechar a tela. Falhas de áudio não impedem jogar.

O fim de jogo tem painel com pontuação, recorde e reinício rápido, e espera a
animação da última jogada terminar. A preferência do sistema por redução de
animações é respeitada. Os testes verificam animação, cores das linhas cruzadas,
som por evento, silêncio, segundo plano, reinício e liberação dos recursos.

Para testar os novos sons, encerre o `flutter run` anterior e execute-o novamente:
o plugin de áudio precisa ser instalado no Android. No aparelho, confira:

- Encaixe válido: som curto; tentativa inválida: sem som e sem perder a peça.
- Limpeza: blocos desaparecem com animação e um toque ascendente.
- Botão de volume: silencia inclusive o som de fim de jogo.
- Fim de jogo: aparece uma única vez e permite reiniciar rapidamente.
- Fechar/reabrir: o recorde permanece; a partida começa vazia.

Os sons podem ser regenerados com `python3 scripts/generate_sounds.py`.

## Ícone Android

O ícone original em `assets/icon/block_puzzle.png` substitui o símbolo do Flutter,
com variantes por densidade e ícone adaptativo. Para regenerar os recursos,
execute `dart run flutter_launcher_icons`. O prompt e a origem da arte estão em
[assets/icon/README.md](assets/icon/README.md).

Mudanças de ícone exigem nova instalação pelo `flutter run` ou pelo APK;
hot reload não altera os recursos do launcher. A atualização do mesmo app
preserva o recorde salvo.

## Fontes de instalação

- [Instalação manual do Flutter](https://docs.flutter.dev/install/manual)
- [Flutter estável e versões](https://docs.flutter.dev/install/archive)
- [Preparação Android](https://docs.flutter.dev/platform-integration/android/setup)
- [Android Command-line Tools](https://developer.android.com/studio#command-tools)

As referências a JDK 17 e Android 34 no plano são a configuração proposta
originalmente. A configuração efetiva será validada com o template do Flutter
instalado e registrada em `docs/ambiente.md`.
