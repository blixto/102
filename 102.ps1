using namespace System.Management.Automation

[CmdletBinding()]
param
(
    [string]$Nome,
    [string]$Numero,
    [string]$Descricao,
    [switch]$Adicionar,
    [switch]$Deletar,
    [switch]$Texto
)

$LISTA = "$PSScriptRoot\\lista.txt"
$MSGS =
@{
    MSMODOS = "Má seleção de modos.";
    MALFORM = "Inserção malformada.";
    NAOENCO = "Dado não encontrado.";
}

$ERROS =
@{
    MSMODOS = [ErrorRecord]::new([Exception]::new($MSGS.MSMODOS), "MSMODOS", [ErrorCategory]::NotSpecified, $null);
    MALFORM = [ErrorRecord]::new([Exception]::new($MSGS.MALFORM), "MALFORM", [ErrorCategory]::NotSpecified, $null);
    NAOENCO = [ErrorRecord]::new([Exception]::new($MSGS.NAOENCO), "NAOENCO", [ErrorCategory]::NotSpecified, $null);
}

function _cx
{
    param
    (
        [string[]]$Textos,
        [int]$Largura = 0,
        [int]$Altura = 0,
        [switch]$CRLF
    )

    $CX =
    @{
        HOR = "`u{2501}"; VER = "`u{2503}";
        ESQ = "`u{2523}"; DIR = "`u{252b}";
        CSE = "`u{250f}"; CSD = "`u{2513}";
        CIE = "`u{2517}"; CID = "`u{251b}";
    }

    $fixo = ($Largura -gt 0 -or $Altura -gt 0)
    $i = 0;
    foreach ($texto in $Textos)
    {
        $linhas = $texto -split (($CRLF)?"`r`n":"`n")
        $maxl = $linhas[0].Length
        $linhas | ForEach-Object `
                  {
                      if ($maxl -lt $_.Length)
                      {
                          $maxl = $_.Length
                      }
                  }

        ($i -eq 0)?"$($CX.CSE)$($CX.HOR * (($fixo)?($Largura - 1):($maxl + 2)))$($CX.CSD)":"$($CX.ESQ)$($CX.HOR * (($fixo)?($Largura - 1):($maxl + 2)))$($CX.DIR)"
        $linhas | ForEach-Object `
                  {
                      $t = $_.Length
                      "$($CX.VER) $($_)$(" " * (($fixo)?($Largura - $t - 2):($maxl - $t + 1)))$($CX.VER)"
                  }

        if ($Altura -gt 0)
        {
            for ($j = 0; $j -lt $Altura; $j++)
            {
                "$($CX.VER)$(" " * (($fixo)?($Largura - 1):($maxl - 1)))$($CX.VER)"
            }
        }

        $i++
    }

    "$($CX.CIE)$($CX.HOR * (($fixo)?($Largura - 1):($maxl + 2)))$($CX.CID)"
}

$msg =
@"
102: Utilitário de Gerenciamento de Lista Telefônica Simples
Copyleft (`u{2184}) 2022 G.R.Rocha - R.F.Brasil
Nenhum direito reservado.
"@,
@"
USO:
.\102 -Nome <nome curto ou expressão regular> \
      [-Numero <número> -Descricao <breve descrição> \
      [-Adicionar|-Deletar|-Texto]]
"@

if ($Nome -match "^(S|s)obre$")
{
    _cx $msg[0] -CRLF
    return;
}
elseif ($Nome -match "^(A|a)juda|\?$" -or $Nome -eq "")
{
    _cx $msg[1] -CRLF
    return;
}

if (($Adicionar -and $Deletar) -or ($Adicionar -and $Texto) -or ($Deletar -and $Texto) -or ($Adicionar -and $Deletar -and $Texto))
{
    $PSCmdlet.WriteError($ERROS.MSMODOS)
    return;
}

if ($Nome -eq "" -or (($Adicionar -or $Deletar)?(-not ($Numero -match "^[0-9]+$")):$false))
{
    $PSCmdlet.WriteError($ERROS.MALFORM)
    return;
}

if (-not (Test-Path $LISTA))
{
    $null >$LISTA
}

$encontrado = $false; $resposta = @()
if ($Adicionar)
{
    "$Nome;$Numero;$Descricao" >>$LISTA
    "Entrada adicionada."
    return;
}
elseif ($Deletar)
{
    $novaLISTA = @()
    $arquivo = Get-Content $LISTA
    foreach ($entrada in $arquivo)
    {
        if (($entrada -split ';')[0] -match $Nome -and ($entrada -split ';')[1] -match $Numero)
        {
            $encontrado = $true
        }
        else
        {
            $novaLISTA += $entrada
        }
    }

    if ($encontrado)
    {
        $novaLISTA >$LISTA
        "Entrada apagada."
    }
    else
    {
        $PSCmdlet.WriteError($ERROS.NAOENCO)
    }

    return;
}
else
{
    $termo = $Nome
    $arquivo = Get-Content $LISTA
    foreach ($entrada in $arquivo)
    {
        if (($entrada -split ';')[0] -match $termo -or ($entrada -split ';')[1] -match $termo)
        {
            $encontrado = $true
            if ($Numero -eq "!" -and -not ($Termo -match "^[0-9]+$"))
            {
                $resposta += @("$(($entrada -split ';')[1])")
            }
            else
            {
                $resposta += @("Nome:      $(($entrada -split ';')[0])`n" +
                               "Número:    $(($entrada -split ';')[1])`n" +
                               "Descrição: $(($entrada -split ';')[2])")
            }
        }
    }
}

if ($encontrado)
{
    if ($Texto)
    {
        $resposta
    }
    else
    {
        _cx $resposta 80
    }
}
else
{
    $PSCmdlet.WriteError($ERROS.NAOENCO)
}

return;
