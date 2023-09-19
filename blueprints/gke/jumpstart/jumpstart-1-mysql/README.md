TODO:
- MySQL password as variable or automatically generated?
- consider creation of MySQL Router after cluster is setup (to prevent misconfiguration of the router if it is bootstrapped before configuration completes)
- permanent IP address for LoadBalancer / DNS name?

Caveats:
* db cluster resize is not properly handled by scripts (changing number of cluster members)
* resizing the cluster requires manually adding new members to the cluster / removing members 
* 