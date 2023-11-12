#!/bin/bash

# Variables
attempt=0
max_attempts=3

# Reading IP address
while [[ $attempt -lt $max_attempts ]]
do
    read -p "Enter the windows IP address that is being managed: " Hostname

    # Use regex to check if the input is a valid IPv4 address
    if [[ $Hostname =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
        echo ">>>>>> Valid IP address: $Hostname"
        break
    else
        echo "Invalid IP address. Please enter a valid IP address."
        ((attempt++))

        # If maximum attempts reached, exit with an error
        if [[ $attempt -eq $max_attempts ]]; then
            echo "Maximum attempts reached!"
            exit 1
        fi
    fi
done

# Test the winrm over HTTPS if the certificate is healthy
result=$(echo 'y' | openssl s_client -connect $Hostname:5986 -showcerts 2>&1) # The '2>&1' redirects stderr to stdout, capturing both in the variable
#result2=$(nc -zvw10 3.92.65.100 5986) # Test is the Port in listening state
# Check the output
if [[ $result == *DONE* ]]; then
    echo ">>>>>> Winrm is ready to use."
elif [[ $result == *Connection\ refused* ]]; then
    echo "There is a firewall issue or the WinRM listener is not running / Configured."
    echo "Hint 1: Try on the Windows machine to list listeners:"
    echo '  >> winrm enumerate winrm/config/listener'
    echo 'Hint 2: If empty, you need to set up a listener HTTP/HTTPS.'
    echo '  >> winrm create winrm/config/listener?Address=*+Transport=HTTPS '"'"'@{Hostname=""'$Hostname'"";CertificateThumbprint=""$Thumbprint"";port=""5986""}'"'"''
else
    echo "Received unexpected output. Notify me with the output to fix the script"
fi
