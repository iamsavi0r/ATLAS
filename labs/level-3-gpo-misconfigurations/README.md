# ATLAS Project: Level 3 - GPO & Share Misconfigurations

You have successfully sprayed the domain and established an initial foothold inside `olympus.local` using the low-privileged `user25` account compromised during Level 2. Now it's time to escalate privileges and move laterally across the internal environment.

Instead of burning zero-days or complex exploits, you'll abuse the number one flaw in modern corporate environments: **administrator negligence and unsecured data stores**.

## Status

The base infrastructure is live. Your objective is to hunt for "forgotten secrets" left behind by the IT department. Administrators love automation, but they often cut corners when handling production credentials — hardcoding passwords into internal scripts, opening network shares to everyone, and leaving static credentials baked into Group Policy Preferences (GPP).

In this lab, you'll learn how to enumerate network-accessible SMB shares and exploit the well-known Microsoft `cpassword` vulnerability.

---

## 🎯 Mission Briefing: Internal Pivot

### Your Starting Point (Foothold Credentials)

You have successfully completed Level 2 and established your internal foothold within the `olympus.local` network. You managed to compromise a low-privileged domain user account via password spraying.

Use the following credentials to authenticate and begin your internal assessment from your Windows 11 workstation or attack box:

* **Domain:** `olympus.local`
* **Username:** `user25`
* **Password:** `Autumn2026!`

> ⚠️ **Note:** `user25` is a standard, low-privileged domain user. You do **not** have local administrative rights on the target hosts yet. Your goal is to escalate your privileges by hunting for corporate secrets.

### Objectives

1. **SMB Share Hunting (Target A):**
   * Enumerate the Domain Controller (`10.0.0.4`) shares using your `user25` active session.
   * Locate the non-standard administrative share (`IT_Automation`) and inspect the automated scripts.
   * Extract the plaintext password for the high-value `backup_svc` account.

2. **GPP cpassword Decryption (Target B):**
   * Access the Active Directory global replication share at `\\olympus.local\SYSVOL\`.
   * Search through the active policies GUID directory tree to locate the legacy `Groups.xml` deployment file.
   * Extract the static `cpassword` string and decrypt it locally to retrieve the plaintext password for the `Local_IT_Admin` account.

### Success Criteria

You've successfully completed Level 3 when you've recovered the plaintext credentials for both `backup_svc` and `Local_IT_Admin`.

With these accounts compromised, you'll have the privilege foothold required to move to **Level 4: The OSINT Breach** — where we step completely outside the internal perimeter.

---

## Step 1. Inject Level 3 Vulnerabilities

Log into your Server Core Domain Controller `atlas_admin` and run the two deployment scripts from `labs/level-3-gpo-share-misconfig/`, in order:

```
# Before reboot: installs the AD DS role and stands up the olympus.local forest
powershell -ExecutionPolicy Bypass -File .\phase1.ps1

# (server reboots automatically — wait 3-5 minutes, reconnect, then:)

# After reboot: injects the Level 3 vulnerabilities (backup_svc, open share, GPP cpassword)
powershell -ExecutionPolicy Bypass -File .\phase2.ps1
```

`phase2.ps1` stands up an unhardened internal network share and drops a legacy, insecure GPP configuration file directly into the Active Directory SYSVOL replica.

---

## Step 2. The Mission (How to Hunt)

Once the setup script finishes, pivot back to your non-domain workstation (or attack machine). Authenticate using your compromised Level 2 user session, and begin internal enumeration.

### Target A: Unsecured Network Shares (SMB Hunting)

1. Enumerate all SMB shares exposed on the Domain Controller (`10.0.0.4`) from the perspective of your standard unprivileged domain account.
2. Locate the automation scripts directory.
3. Extract the plaintext, hardcoded service account credentials for `backup_svc`.

### Target B: Group Policy Preference `cpassword` Abuse

1. Legacy Active Directory deployments used Group Policy Preferences to push local administrative accounts to workstations. Microsoft encrypted these passwords with AES-256 — but the static decryption key ended up published on MSDN, which broke the scheme for good.
2. Enumerate and search the live `\\olympus.local\SYSVOL\` directory tree for configuration files.
3. Locate the `Groups.xml` file buried in the Policies GUID directory.
4. Extract the `cpassword` attribute and decrypt it locally with standard offensive tooling.

---

## What's Next?

Once you've extracted the `backup_svc` credentials and decrypted the `Local_IT_Admin` plaintext password (`ZeusLightning2026!`), you've successfully demonstrated domain-wide misconfiguration auditing.

Clear your session footprint and prepare for **Level 4: The OSINT Breach**.
