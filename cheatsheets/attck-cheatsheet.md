Threat/CoA matrix

|                       | Deceive                           | Detect                | Deny/Degrade                                 |   Destroy              |
| -------------         | ---------------                   | --------              | --------------                               | ---------              |
| Recon                 | Honeypots, Self-profiling         | Sensors, Canaries     | Gateway Firewalls, Honeypots                 | Counter-acts           |
| Weaponization         |                                   | Research              | NIPS                                         |                        |                     
| Delivery              |                                   | NIDS (net IDS)        | vigilence, in-line AV                        |                        |                       
| Execution             |                                   | HIDS (host IDS)       | patches, DEP                                 |                        |                       
| Persistence           |                                   |                       | jails, AV                                    |                        |                       
| .  Defence Evasion    |                                   |                       |                                              |                        |                       
| .  Credential Access  |                                   |                       |                                              |                        |                       
| .  Discovery          |                                   | Internal Firewalls    |                                              |                        |                       
| .  Lateral Mov't      |                                   |                       | ACLs                                         |                        |                       
| .  Collection         |                                   |                       | Encryption                                   |                        |                       
| C2                    |                                   |                       | DNS redirect                                 |                        |                       
| .  Exfiltration       |                                   |                       | Tarpits                                      |                        |                       
| Actions on            |                                   | Audit log             | QoS                                          |                        |                           

===

6 D's:

Deceive:            To mislead or trick an adversary by providing false information or setting up decoy systems. 

Detect:             To determine if an intruder or adversary is present and active.

Deny:               To prevent an adversary from gaining access to or information from a system or network. 

Degrade/Delay:      To reduce the effectiveness or efficiency of an adversary's activities or systems without necessarily stopping them completely. 

Destroy:            To permanently damage an adversary's infrastructure or systems so they can no longer function

===

Cyber Kill Chain vs ATTC&K

| CKC/ATTC&K                                |                                          | ATTC&K extra steps     |                                           |
| -----------------                         | ---------------------------------------- | --------------------   | ----------------------------------------  |
| 1.  Reconnaisance                         | Gather information                       |                        |                                           |
| 2.  Weaponization/Resource Development    | Build tools and payload                  |                        |                                           |
| 3.  Delivery/Initial Access               | Deploy tools                             |                        |                                           |
| 4.  Exploitation/Execution                | Execute payload                          |                        |                                           |
| 5.  Installation/Persistence              | Gain foothold                            |                        |                                           |
|                                           |                                          | Defense evasion        | Avoid detection                           |
|                                           |                                          | Credential access      | Determine credentials                     |
|                                           |                                          | Discovery              | Figure out environment                    |
|                                           |                                          | Lateral Movement       | Move through environment                  |
|                                           |                                          | Collection             | Gather data of interest to goal           |
| 6.  C2                                    | Establish comms with compromised systems |                        |                                           |
|                                           |                                          | Exfiltration           | Exfiltrate data of interest               |
| 7.  Actions on/Impact                     | Accomplish goals                         |                        |                                           |