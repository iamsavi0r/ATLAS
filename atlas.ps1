Clear-Host

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   🌍 Welcome to ATLAS (Low-Resource AD Labs) 🌍   " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Accessible Training Labs for Active-directory Security." -ForegroundColor Gray
Write-Host ""

Write-Host "Choose an action:" -ForegroundColor Yellow
Write-Host "[1] Deploy Level 1: Beginner AD (Kerberoasting & AS-REP Lab)"
Write-Host "[2] Deploy Level 2: Smart Recon & Password Spraying (100+ Users)"
Write-Host "[3] Destroy Infrastructure (Stop & Delete everything to save money)"
Write-Host "[4] Exit"
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

# Запоминаем корневую папку проекта, чтобы PowerShell всегда мог вернуться назад
$RootDir = Get-Location

switch ($choice) {
    "1" {
        Write-Host "`n[+] Starting deployment of Level 1..." -ForegroundColor Green
        Set-Location "$RootDir\labs\level-1-basic"
        terraform init
        terraform apply -auto-approve
        Set-Location $RootDir
        Write-Host "`n[+] Level 1 deployed successfully!" -ForegroundColor Green
    }
    
    "2" {
        Write-Host "`n[+] Starting deployment of Level 2 (Smart Recon & Password Spraying)..." -ForegroundColor Green
        Set-Location "$RootDir\labs\level-2-password-spraying"
        terraform init
        terraform apply -auto-approve
        Set-Location $RootDir
        Write-Host "`n[+] Level 2 deployed successfully! 2 VMs are live in Azure." -ForegroundColor Green
    }
    
    "3" {
        Write-Host "`n[!] WARNING: This will completely delete the deployed infrastructure!" -ForegroundColor Red
        Write-Host "Which level do you want to destroy?" -ForegroundColor Yellow
        Write-Host "[1] Destroy Level 1"
        Write-Host "[2] Destroy Level 2"
        
        $destroyChoice = Read-Host "Enter choice (1-2)"
        $confirm = Read-Host "Are you absolutely sure? (y/n)"
        
        if ($confirm -eq "y") {
            if ($destroyChoice -eq "1") {
                Write-Host "`n[-] Destroying Level 1..." -ForegroundColor Red
                Set-Location "$RootDir\labs\level-1-basic"
                terraform destroy -auto-approve
            } elseif ($destroyChoice -eq "2") {
                Write-Host "`n[-] Destroying Level 2..." -ForegroundColor Red
                Set-Location "$RootDir\labs\level-2-password-spraying"
                terraform destroy -auto-approve
            } else {
                Write-Host "`n[!] Invalid choice. Destruction aborted." -ForegroundColor Red
                Set-Location $RootDir
                break
            }
            Set-Location $RootDir
            Write-Host "`n[+] Infrastructure destroyed successfully. 0$ spent!" -ForegroundColor Green
        }
    }
    
    "4" {
        Write-Host "`nGoodbye! Happy hacking!" -ForegroundColor Cyan
        Exit
    }
    
    Default {
        Write-Host "`n[!] Invalid choice. Please run the script again." -ForegroundColor Red
    }
}
