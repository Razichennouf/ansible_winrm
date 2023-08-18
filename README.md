# Winrm management made easier : 
This script empowers you to effortlessly configure and manage WinRM settings, certificates, firewall rules, and user accounts – all essential components for a successful Ansible integration. No more manual trial and error; our automation utilities handle the complexity, leaving you with a reliable, consistent, and secure environment ready to power your Ansible-driven operations.

Tested on : 5.1.20348.1850 Powershell Version

<h1>Menu:</h1> 

![image](https://github.com/Razichennouf/ansible_winrm/assets/77803582/662e3747-f187-4b31-a65a-ca3f4cac6f22)

<h1>WinRM Deployment Utilities</h1>

<p>This PowerShell script provides a comprehensive set of automation utilities for managing WinRM (Windows Remote Management) configurations, making the setup and management of WinRM easier and more efficient.</p>

<h2>Features:</h2>
<ul>
    <li><strong>PowerShell Remoting:</strong> Enable PowerShell Remoting with a single command, facilitating remote management and administration.</li>
    <li><strong>WinRM Configuration:</strong> Configure WinRM client and server settings, optimizing security and functionality.</li>
    <li><strong>AWS-specific Settings:</strong> Dynamically configure settings tailored for AWS environments, ensuring seamless integration.</li>
    <li><strong>Firewall Management:</strong> Set up necessary firewall rules for WinRM ports, simplifying remote access setup.</li>
    <li><strong>Automation User Setup:</strong> Create and set up automation users with ease, enhancing security and control.</li>
    <li><strong>Certificate Management:</strong> Manage SSL Self-signed certificates for secure communication, simplifying certificate handling.</li>
    <li><strong>WinRM Configuration:</strong> Configure WinRM to enable HTTPS and create listeners, streamlining remote management.</li>
    <li><strong>Administrator Tools:</strong> Additional utilities for certificate deletion, permission group checks, and more.</li>
</ul>

<h2>Benefits:</h2>
<ul>
    <li><strong>Efficiency:</strong> Automate complex WinRM configuration tasks, reducing manual effort and potential errors.</li>
    <li><strong>Consistency:</strong> Ensure consistent and secure configurations across multiple systems.</li>
    <li><strong>Streamlined Setup for Ansible:</strong> This script lays the groundwork for easy integration with Ansible, facilitating seamless automation of tasks.</li>
    <li><strong>Enhanced Security:</strong> Configure WinRM settings, certificates, and user accounts to meet security best practices.</li>
    <li><strong>Visual Feedback:</strong> Interactive menu-driven design with ANSI color coding provides clear status updates and prompts.</li>
</ul>
<h2>Ansible Collection : </h2>
<ul>
    <li> <code>ansible-galaxy collection install ansible.windows</code></li>
    <li> <strong>Hint:</strong> When you are using the modules in <strong>Playbooks</strong> you need to specifiy the whole objects <code>ansible.windows.win_service_info</code> </li>
</ul>

![image](https://github.com/Razichennouf/ansible_winrm/assets/77803582/c6f114df-3550-44d9-b5c7-c166037a276d)

<p>By leveraging these utilities, WinRM management becomes a breeze, and your environment gains enhanced security, efficiency, and consistency.</p>

<p><strong>Important:</strong> While these utilities simplify WinRM management, remember to review and adjust configurations before deploying them in a production environment. Security and specific requirements may vary, so always ensure that settings are aligned with your organization's standards.</p>
