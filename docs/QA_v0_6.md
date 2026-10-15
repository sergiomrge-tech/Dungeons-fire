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
