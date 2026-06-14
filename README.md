# ATLAS
🌍 ATLAS (Accessible Training Labs for Active-directory Security)


# 🌍 ATLAS (Accessible Training Labs for Active-directory Security)

> **Forget about 24GB RAM requirements and expensive SSDs. ATLAS is a lightweight infrastructure-as-code automation tool designed to spin up vulnerable Active Directory environments for Red Teamers and students on low-spec hardware or within cloud Free Tiers in just a few minutes.**

---

## 🛑 The Problem ATLAS Solves

Existing automated lab builders (like GOAD) are incredible tools, but they are built for heavy workstations. Their system requirements usually start at **20-24GB of RAM** and fast SSDs. 

**What about students running on older laptops with 8GB RAM and slow HDDs?** Or those who don't want to spend an entire week doing tedious Windows Server administration just to practice a single attack vector?

**ATLAS removes this pain.** It is built from the ground up with a strict focus on **Low-Resource Engineering**.

---

## 🔥 Key Features & Value Proposition

* **Low-Spec Friendly (True Accessibility):** The architecture is highly optimized to run on environments with **8GB of RAM (or even 4GB)**. By utilizing headless **Windows Server Core** and sequential VM provisioning, your old HDD won't choke.
* **Cloud-First & Free Tier Ready:** Terraform/Ansible scripts are tailored to fit perfectly into cloud provider free tiers (e.g., AWS `t2.micro`). Deploy your lab to the cloud with a single command—spending $0 and using 0% of your local hardware resources.
* **Modular Construction:** You don't need to spin up 5 heavy domain controllers just to practice one attack. Choose your specific scenario from an interactive menu:
  * `[1] Beginner AD (Kerberoasting Lab)`
  * `[2] AS-REP Roasting Lab`
  * `[3] Under Development...`

---

## 🛠 Tech Stack Under the Hood

The project is currently in active development (MVP phase). The main focus is lightweight automation:
* **IaC / Orchestration:** [Terraform / powershell / UserData]
* **OS Configuration:** PowerShell Core / Ansible
* **Target OS:** Windows Server Core (Evaluation Edition)

---

## 🗺 Roadmap

- [ ] **MVP Release:** Automated deployment script for a single DC (Server Core) with misconfigured SPN accounts for Kerberoasting.
- [ ] AWS/Azure Free Tier integration templates.
- [ ] Additional attack scenarios: AS-REP Roasting, ACL abuse, and DCSync.
- [ ] Interactive CLI menu for lab management.

---

## 🤝 Author & Contacts

* **Author:** savi0r (`@btwsavi0r`)
* **Dev Blog (Backstage & Progress):** [https://www.instagram.com/atlas.project.w/ / https://medium.com/@savi0r]

*If you believe cybersecurity education should be accessible to everyone, regardless of their hardware—please drop a ⭐ to support the project!*
