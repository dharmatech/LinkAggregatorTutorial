
# 0.2 2021-04-11

# cd .\Dropbox\Documents\VisualStudio\LinkAggregatorTutorial

param([switch]$gist)

(Get-Content .\LinkAggregatorTutorial.ps1 -Raw) -replace '(?s)# IGNORE-START.*?# IGNORE-END', '' | Set-Content pass-1.ps1

(Get-Content .\pass-1.ps1 -Raw) -replace "\`$file = '(.*?)'", ("`n---`n" + 'File: `$1`')  | Set-Content pass-1.ps1

# Explanation of (?s) in regex below
# https://stackoverflow.com/a/12573413/268581

(Get-Content .\pass-1.ps1 -Raw) -replace '(?s)\$original_text = @"(.*?)"@', ("Original text: `n" + '```$1```') | Set-Content pass-1.ps1

(Get-Content .\pass-1.ps1 -Raw) -replace '(?s)\$replacement_text = @"(.*?)"@', ("Replacement text: `n" + '```$1```') | Set-Content pass-1.ps1

# (Get-Content .\pass-1.ps1 -Raw) -replace ('(?s)^@"(.*?)"@ \| ' + "Set-Content '(.*?)'"), ('File: `$2`' + "`n`n" + '```$1```')  | Set-Content pass-1.ps1

# (Get-Content .\pass-1.ps1 -Raw) -replace ('(?s)@"(.*?)"@ \| ' + "Set-Content '(.*?)'"), ('File: `$2`' + "`n`n" + '```$1```')  | Set-Content pass-1.ps1

# (?sm)
# s    use single-line mode
# m    use multiline mode

# (.*?)
# .    any character    
# *?   zero or more times, but as few times as possible

(Get-Content .\pass-1.ps1 -Raw) -replace ('(?sm)^@"(.*?)"@ \| ' + "Set-Content '(.*?)'"), ('File: `$2`' + "`n`n" + '```$1```')  | Set-Content pass-1.ps1


# diff

(Get-Content .\pass-1.ps1 -Raw) -replace   '(?sm)^@"(.*?)"@ \| git apply --whitespace=nowarn',    ('```diff $1```')    | Set-Content pass-1.ps1

# (Get-Content .\pass-1.ps1 -Raw) -replace   '(?sm)^@"(.*?)"@ \| git apply',                        ('```diff $1```')    | Set-Content pass-1.ps1


(Get-Content .\pass-1.ps1) | ForEach-Object {

    if     ($_ -match '^# ')                      { $_ -replace '^# ', '' }
    elseif ($_ -match '^#')                       { $_ -replace '^#',  '' }
    elseif ($_ -match "^cmt '")                   { $_ -replace "^cmt '(.*)'", '$1' }
    elseif ($_ -match '^cmt "')                   { $_ -replace '^cmt "(.*)"', '$1' }
    elseif ($_ -match '^Edit \$file -Replacing')  { }
    elseif ($_ -match 'IGNORE-LINE-FOR-MARKDOWN') { }
    else { $_ }

} | Set-Content LinkAggregatorTutorial.md

if ($gist)
{
    $result = gh gist create LinkAggregatorTutorial.md
    
    Start-Process $result
}

Remove-Item .\pass-1.ps1