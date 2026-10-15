# God of War III — Dublagem PT-BR para o port nativo de PC

Projeto comunitário para aplicar áudio em Português do Brasil ao port nativo de PC de **God of War III** que utiliza a estrutura de dados `CUSA01623`.

## Estado do projeto

A conversão foi validada na instalação usada durante o desenvolvimento:

- 1142 streams de áudio convertidos e validados;
- 17 cinematics convertidas;
- áudio em Português do Brasil;
- estrutura de destino: `PORTUGUESE\SOUNDS\STREAMS_PS4`;
- instalador com backup automático.

## Importante

Este repositório **não inclui o jogo completo, executáveis do jogo, arquivos originais de backup nem conteúdo desnecessário da instalação**.

Você precisa possuir sua própria instalação compatível de God of War III.

## Estrutura esperada do jogo

O instalador espera uma pasta de jogo semelhante a:

```text
CUSA01623\
└── PORTUGUESE\
    └── SOUNDS\
        └── STREAMS_PS4\
```

## Instalação

1. Baixe/extraia o pacote do projeto.
2. Coloque os arquivos do patch em `patch\PORTUGUESE\SOUNDS\STREAMS_PS4`.
3. Abra PowerShell.
4. Execute:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\Instalar-PTBR.ps1"
```

O script solicitará a pasta `CUSA01623`, fará backup dos arquivos que forem substituídos e instalará o patch.

Também é possível informar a pasta diretamente:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\Instalar-PTBR.ps1" -GameDir "C:\Games\God of War III PTBR\Jogo\CUSA01623"
```

## Restaurar

Para restaurar os arquivos que foram substituídos:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\Restaurar-Original.ps1" -GameDir "CAMINHO\PARA\CUSA01623"
```

## Compatibilidade

Este projeto foi preparado para o port nativo de PC cuja instalação utiliza a estrutura `CUSA01623`. Não é um patch para emulador de PS3 e não é um instalador para console PS4.

## Aviso

God of War e seus respectivos conteúdos pertencem aos seus detentores de direitos. Este é um projeto comunitário não oficial e não é afiliado ou endossado pelos detentores da propriedade intelectual.

O repositório foi estruturado para não distribuir o jogo completo ou seus executáveis.
