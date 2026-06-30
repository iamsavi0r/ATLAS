# ATLAS Project: Level 4 - The OSINT Breach

You have successfully escalated your privileges inside the internal Active Directory network during Level 3. However, internal domination is only half the battle. Modern enterprise networks are heavily reliant on cloud infrastructure, remote workers, and external SaaS gateways. 

Now, we step completely outside the internal perimeter. Welcome to the open wilderness.

---

## Status

The corporate perimeter of Olympus Global is live. Your objective is to secure initial access from the outside, targeting their exposed remote-work infrastructure and the human element.

* **Target Domain:** `main.olympicbusiness.online`
* **Target VPN Gateway:** `vpn.olympicbusiness.online`

> ⚠️ **Note:** The corporate VPN gateway "SecureConnect" is hardened with a strict **403 Forbidden** rule for all external connections. Direct brute-forcing or loud automated scanning will yield nothing. (also you can do phishing)

There are multiple independent paths available to breach this perimeter. Choose your methodology, conduct your reconnaissance, and find a way inside.

---

## Success Criteria

You've successfully completed Level 4 when you have bypassed the external access controls, intercepted valid employee credentials, and successfully authenticated to the `vpn.olympicbusiness.online` portal.

Good luck.
