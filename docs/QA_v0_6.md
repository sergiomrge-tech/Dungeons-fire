# Combate, partículas e luzes — v0.6.0

## Alterações

Preservados personagens, cenários, hitboxes, custos/cooldowns e regras de progressão da v0.5. Cada combo recebe preparação, contato e recuperação com peso próprio. Personagens têm flash curto e recuo visual nos acertos; Varek usa a pose de golpe na técnica de avanço.

A camada visual é código nativo Godot: fitas de luz, brasas, poeira, detritos, fragmentos arcanos, folhas, impactos e escudo. Cores dourada, violeta e verde distinguem os três heróis. Partículas integram velocidade, gravidade, arrasto, rotação e opacidade. Projéteis têm rastros e silhuetas diferentes para flechas e energia arcana. Chefes ganham impacto com detritos e luz, mantendo seus avisos visíveis.

Limites fixos: 240 partículas reutilizadas, 36 efeitos, seis PointLight2D sem sombras, 48 projéteis e oito pontos por rastro. As luzes alcançam o cenário e os atores; a interface fica em outro canvas. Efeitos não causam dano por conta própria nem entram no save.

## Validação

Import/parser e auditoria locais sem erro. Suíte nova: 58 verificações de sincronismo com o dano, identidade por herói, guard cancelado, partículas móveis, limites, expiração, limpeza de luzes e compatibilidade do save. As 139 verificações de campanha e o bot de combate também passaram localmente.

O workflow registra PNGs e vídeos do framebuffer real e compara a mesma cena com PointLight2D ligado/desligado. O Android usa exportação isolada de QA para verificar partículas/efeito de habilidade e repetir multitouch, pausa e retomada. Registrar a conclusão e o checksum do APK após a revisão dos artefatos.

## Limites

As oito poses autoradas de cada atlas continuam sendo a fonte. O refinamento de animação usa ritmo, transições de pose e transformações discretas; não foram criados novos desenhos de personagem. A gravação visual é uma sequência controlada executando os mesmos pedidos de ataque e habilidades do jogo. FPS e aquecimento no celular físico não foram medidos.

## Conclusão — 15/10/2026

Runtime do APK: `0027279d54e7de156be780119236797057213fa8`, teste Android `38744737248`, aprovado. Fonte das capturas e vídeos: `de949ec0efe4da6cf38b494c970896dfae5fa0b3`, validação `38744892459`, aprovada. A diferença entre essas fontes é documentação e ferramentas de captura; os scripts/recursos exportados do jogo são os mesmos.

A comparação do framebuffer com luz ligada/desligada mediu soma de diferenças RGB de 40,7019605953246 na área de teste, confirmando iluminação nativa. Revisados os PNGs dos três heróis, GIF de Varek e gravações reais concatenadas em vídeo de 16,5 s. As primeiras tentativas identificaram ausência de ffmpeg no runner e uma expectativa de loot do teste Android que não considerava um inimigo derrotado pela habilidade; os dois problemas foram corrigidos.

Android API 29: nove verificações iniciais (incluindo partículas e preparação de habilidade), duas de pausa e sete de retomada aprovadas. Imagem não vazia e logcat sem erros do jogo. Coleta diagnóstica em emulador por software: média 7,50 FPS em 38 frames e pior frame 149,057 ms; isto não comprova desempenho em aparelho físico.

APK público arm64, API 24+, versão 0.6.0/código 600, pacote `com.sergiomrge.dungeonsfires.preview.v060`, 49.423.556 bytes. Assinatura, alinhamento de 16 KB e CRC aprovados. SHA256 `a6ad41ea75dd45fec66d3e7c9de6ac8557970118223cfe1d963e4251a826230a`. A exportação inclui `combat_vfx.gdc` e exclui os testes, masters, ferramentas e driver de QA. Instala ao lado das prévias anteriores; saves desses outros pacotes não migram automaticamente.
