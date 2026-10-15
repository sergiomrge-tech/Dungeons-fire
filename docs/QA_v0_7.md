# Validação v0.7.0 — 15/10/2026

## Resultado

Projeto importado no Godot 4.6.1 estável; auditoria de arquivos aprovada (216 arquivos, nenhuma referência quebrada ou arquivo inesperado). Os testes abaixo passaram localmente após a implementação:

| Área | Resultado |
| --- | --- |
| Campanha, compras, saves e multitouch | 139 verificações; 15 masmorras e 75 salas |
| Combate automatizado com Varek e Garron | Ambos concluíram as lutas |
| Refúgio, diário e transições | Aprovado |
| Interface clássica | 9 ações de navegação, save e seleção de herói aprovados |
| Mina dos Sinos | 34 verificações; salas, chefe e recompensa aprovados |
| Entrada escalada por viewport | Aprovada |
| Animações, luz e efeitos de combate | 58 verificações aprovadas |
| Atlas e HUD existentes | 14 atlas, 112 poses, 14 retratos, 6 cenários e tempos de ataque aprovados |
| Sistemas v0.7 | 41 verificações: 5 mobs, 8 bênçãos, 3 contratos, 4 projetos, rotas, salvamento, sinergias e legibilidade dos novos menus |

O workflow `.github/workflows/validate.yml` captura cinco cenas do framebuffer real: os novos mobs, contratos, escolha de rota, bênçãos e projetos do refúgio. O APK legado permanece inalterado; esta revisão valida o projeto Godot.

## Sistemas incluídos

- Rotas seguras e de risco com três bênçãos sorteadas por escolha; ofertas repetidas podem ser refeitas uma vez após construir a Mesa de Cartografia.
- Sinergias de combate entre Maela, Varek e Neris, com efeitos distintos e recarga própria.
- Contratos opcionais com condições, falha identificável e recompensas extras ao concluir a expedição.
- Cinco moradores resgatáveis e quatro projetos permanentes com desbloqueio por progresso, custo e benefício.
- Cinco novas famílias de mobs com atlas, paletas, comportamento e regiões de aparição próprios.

## Limites conhecidos

Os cinco atlas de mobs são variações de paleta sobre sprites originais já existentes e preservam suas animações; não são cinco ilustrações inteiramente novas. O APK não foi reconstruído nesta etapa.
