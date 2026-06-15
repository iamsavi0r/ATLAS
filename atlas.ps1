Clear-Host

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   🌍 Welcome to ATLAS (Low-Resource AD Labs) 🌍   " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Accessible Training Labs for Active-directory Security." -ForegroundColor Gray
Write-Host ""

Write-Host "Choose an action:" -ForegroundColor Yellow
Write-Host "[1] Deploy Level 1: Beginner AD (Kerberoasting & AS-REP Lab)"
Write-Host "[2] Deploy Level 2: Advanced AD (Under Development...)"
Write-Host "[3] Destroy Infrastructure (Stop & Delete everything to save credits)"
Write-Host "[4] Exit"
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host "`n[+] Starting deployment of Level 1..." -ForegroundColor Green
        # Скрипт сам переходит в нужную папку и запускает Terraform
        Set-Location ".\labs\level-1-basic"
        terraform init
        terraform apply -auto-approve
        Write-Host "`n[+] Level 1 deployed successfully! Check your Azure Portal." -ForegroundColor Green
    }
    "2" {
        Write-Host "`n[-] This level is under development. Stay tuned!" -ForegroundColor Yellow
    }
    "3" {
        Write-Host "`n[!] WARNING: This will delete the infrastructure!" -ForegroundColor Red
        $confirm = Read-Host "Are you sure? (y/n)"
        if ($confirm -eq "y") {
            # Скрипт сам зачищает папки
            Set-Location ".\labs\level-1-basic"
            terraform destroy -auto-approve
            Write-Host "`n[+] Infrastructure destroyed successfully. 0$ spent!" -ForegroundColor Green
        }
    }
    "4" {
        Write-Host "`nGoodbye, user!" -ForegroundColor Cyan
        Exit
    }
    Default {
        Write-Host "`n[!] Invalid choice. Please run the script again." -ForegroundColor Red
    }
}
