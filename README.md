# ATLAS

## 🌍 ATLAS (Accessible Training Labs for Active-directory Security)

> **Forget about 24GB RAM requirements and expensive SSDs. ATLAS is a lightweight infrastructure-as-code automation tool designed to spin up vulnerable Active Directory environments for Red Teamers and students on low-spec hardware or within cloud Free Tiers in just a few minutes.**

---

## 🛑 The Problem ATLAS Solves

Existing automated lab builders (like GOAD) are incredible tools, but they are built for heavy workstations. Their system requirements usually start at **20-24GB of RAM** and fast SSDs. 

**What about students running on older laptops with 8GB RAM and slow HDDs?** Or those who don't want to spend an entire week doing tedious Windows Server administration just to practice a single attack vector?

**ATLAS removes this pain.** It is built from the ground up with a strict focus on **Low-Resource Engineering**.

---

## 🔥 Key Features & Value Proposition

* **Low-Spec Friendly (True Accessibility):** The architecture is highly optimized to run on environments with **8GB of RAM (or even 4GB)**. By utilizing headless **Windows Server Core** and sequential VM provisioning, your old HDD won't choke.
* **Cloud-First & Free Tier Ready:** Terraform scripts are tailored to fit perfectly into cloud provider free tiers. Deploy your lab to the cloud with a single command—spending $0 and using 0% of your local hardware resources.
* **Modular Construction:** You don't need to spin up 5 heavy domain controllers just to practice one attack. Choose your specific scenario from an interactive menu:
  * `[1] Beginner AD (Kerberoasting Lab)`
  * `[2] AS-REP Roasting Lab`
  * `[3] Under Development...`

---

## 🛠 Tech Stack Under the Hood

The project is currently in active development (MVP phase). The main focus is lightweight automation:
* **IaC / Orchestration:** [Terraform / PowerShell / UserData]
* **OS Configuration:** PowerShell Core
* **Target OS:** Windows Server Core (Evaluation Edition)

---

## 🚀 How to Use (Step-by-Step Deployment)

Follow these simple steps to spin up your lightweight Active Directory lab in the Azure Cloud.

### 📋 Prerequisites
Before you start, make sure you have the following installed on your host machine:
* **Terraform** (v1.0.0 or higher)
* **Azure CLI** (`az` tool)
* **PowerShell** (Windows built-in, or PowerShell Core for Linux/macOS users)

### 🛠️ Execution Guide

#### Step 1: Clone the Repository
Open your terminal or PowerShell window and download the project files:
`git clone https://github.com/iamsavi0r/ATLAS.git`
`cd ATLAS`

#### Step 2: Authenticate with Azure
Log into your Azure account via the official CLI:
`az login`
*(A browser window will open. Sign in using your Microsoft Azure credentials)*

#### Step 3: Run the Interactive Script
Execute the main automation orchestrator script:
`.\atlas.ps1`

#### Step 4: Choose Your Option
Once the interactive console menu pops up, select your action:
* Type **1** and hit Enter to automatically initialize Terraform and deploy **Level 1 (Olympus Domain Controller)**.
* Wait about 5-7 minutes for Azure to fully provision the virtual machine and apply the post-reboot AD configuration magic.

#### Step 5: Start Pentesting!
Once the deployment finishes, the script will output the **Public IP Address** of your Domain Controller. You can now use tools like Impacket from your attacker machine:
* For AS-REP Roasting: `GetNPUsers.py olympus.local/ -usersfile users.txt -dc-ip <TARGET_IP>`
* For Kerberoasting: `GetUserSPNs.py olympus.local/prometheus:<PASSWORD> -request -dc-ip <TARGET_IP>`

---

### 🛑 CRITICAL: Avoid Extra Charges (Cleanup)

To ensure your cloud usage stays 100% within the Free Tier or low-budget limits, **always destroy the lab when you are done practicing!**

1. Run the script again: `.\atlas.ps1`
2. Type **3** and hit Enter to wipe out the entire cloud environment.
3. This single command will cleanly delete the resource group, saving you from any unexpected subscription billing.

---

## 🗺 Roadmap

- [x] **MVP Release:** Automated deployment script for a single DC (Server Core) with misconfigured accounts for Kerberoasting and AS-REP Roasting.
- [ ] AWS/Azure Free Tier integration templates.
- [ ] Additional attack scenarios: ACL abuse, and DCSync.
- [ ] Interactive CLI menu for lab management.

---

## 🤝 Author & Contacts

* **Author:** savi0r (`@btwsavi0r`)
* **Dev Blog (Backstage & Progress):** [https://www.instagram.com/atlasprojectsec/ / https://medium.com/@savi0r]

*If you believe cybersecurity education should be accessible to everyone, regardless of their hardware—please drop a ⭐ to support the project!*
