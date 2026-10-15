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
