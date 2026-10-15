# Validação v0.5.0 — Primeira região

## Implementação

Godot 4.6.1, física a 60 Hz, Android arm64/API 24+, paisagem, funcionamento offline. Preservados os IDs dos 120 itens e 15 masmorras, os sprites aprovados, o hub e o mapa clássico. Masters e importação técnica da Mina ficam registrados no repositório.

## Evidência nativa local

- Import/editor: sem erro de parser ou referência.
- Auditoria: pacote legado preservado, nenhuma referência quebrada ou arquivo temporário inesperado.
- Campanha: 139 verificações, 15 masmorras e 75 salas.
- Primeira região: 34 verificações de combo/buffer, colisões e navegação, baús/descanso/retomada, defesa frontal/traseira, efeito da relíquia, avisos/fases/recuperação e migração de receitas.
- Bots jogam a Mina e a Fortaleza usando movimento, golpes, técnicas, esquiva e poções, sem forçar morte de inimigos. Isso verifica o fluxo; não estabelece balanceamento ou duração final para jogadores humanos.
- Suítes de interface clássica, refúgio e assets aprovadas localmente.

## Android e imagens

O workflow exporta primeiro o APK arm64 público, verifica CRC, assinatura, alinhamento de 16 KB, recursos novos e ausência de scripts internos. Só depois injeta o driver numa cópia de QA e exporta x86_64. O driver usa eventos InputEventScreenTouch sintéticos de três contatos e o host controla HOME, encerramento do processo e nova abertura por ADB. Os relatórios distinguem esses testes de toque físico.

A revisão da primeira execução detectou um erro de animação ao pausar salas com props (loop de atores também continha objetos); o loop agora filtra DFActor e o teste cobre a pausa nessas salas. O backend gráfico legado do emulador também falhou na compilação de shaders e produziu tela vazia; o runner passou a usar ANGLE/SwiftShader (swangle), com verificação de diversidade de pixels e rejeição de erros no logcat.

O workflow de validação captura o framebuffer real do Godot com Xvfb; o Android registra screenshots por ADB. Registrar a execução e seus resultados abaixo após conclusão. Não apresentar pinturas de ambiente como screenshots do jogo.

## Limites

Nenhum aparelho físico está disponível neste ambiente. FPS, aquecimento, latência do touchscreen e consumo no celular precisam de medição real. A coleta curta em emulador serve para diagnosticar travamentos, não comprovar 60 FPS em aparelhos. Novas prévias usam IDs próprios e não importam automaticamente o save da versão Android anterior.

A direção visual foi preservada; estas mudanças não substituem a revisão visual e de sensação de combate pelo usuário.

## Resultado final de CI — 15/10/2026

Fonte executável validada: `b17576130a2ba0f9c9f3349f76ecd0690e325180`. Validação nativa + framebuffer: run `38740494653`, aprovada. Exportação + Android: run `38740494914`, job `116440625390`, aprovado.

Android API 29/x86_64 com swangle: sete verificações iniciais, duas de pausa e sete de retomada, todas aprovadas. Capturas ADB mostram o jogo renderizado e a pausa após retomada. Logcat final sem SCRIPT ERROR, ERROR do Godot ou FATAL EXCEPTION. O teste reiniciou o processo e confirmou sala 3, vida 73, uma poção, baú aberto e saque 30 ouro/4 minério. Os três contatos são eventos sintéticos, não toque físico.

Coleta diagnóstica curta: 38 frames em aproximadamente cinco segundos, média 7,49 FPS, pior frame 150 ms e memória estática 32.944.806 bytes no emulador por software. Este resultado não é benchmark do celular; a meta de 60 FPS em aparelhos não foi comprovada.

APK arm64 entregue: versão 0.5.0, código 500, pacote `com.sergiomrge.dungeonsfires.preview.v050`. CRC, assinatura e alinhamento de 16 KB aprovados; recursos da Mina e dos chefes presentes, ferramentas/testes/masters/chaves ausentes. SHA256: `fca94bac55cc9e832793fedaf14810257f4146e06620781c77ca8cd464b615c3`.

A prévia usa identidade Android própria e instala ao lado das versões anteriores, sem importar automaticamente seus saves. O save Godot mantém compatibilidade dentro do mesmo armazenamento.
