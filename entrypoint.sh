#!/bin/sh

set -e

kubectlVersion="$1"
helmVersion="$2"
helmSecretsVersion="$3"
kubeConfigData="$4"
sopsAgeKeyFileInBase64="$5"
command="$6"

if [ "$kubectlVersion" = "latest" ]; then
  kubectlVersion=$(curl -Ls https://dl.k8s.io/release/stable.txt)
fi

echo "using kubectl@$kubectlVersion"
echo "using helm@$helmVersion"
echo "using helm-secrets@$helmSecretsVersion"
cat /etc/*release

# Installing kubectl
curl -sLO "https://dl.k8s.io/release/$kubectlVersion/bin/linux/amd64/kubectl" -o kubectl
chmod +x kubectl
mv kubectl /usr/local/bin

# Installing helm secrets
wget https://get.helm.sh/helm-$helmVersion-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm 
chmod +x /usr/local/bin/helm

# Installing helm secrets
helm plugin install "https://github.com/jkroepke/helm-secrets" --version $helmSecretsVersion

# Extract the base64 encoded config data and write this to the KUBECONFIG
echo "$kubeConfigData" | base64 -d > /tmp/kubeConfigData
chmod g-r /tmp/kubeConfigData
export KUBECONFIG=/tmp/kubeConfigData

# Extract the base64 encoded age file for encryption
echo "$sopsAgeKeyFileInBase64" | base64 -d > /tmp/age-key.txt
export SOPS_AGE_KEY_FILE=/tmp/age-key.txt

# Printing the command executed inside this action, just for troubleshooting
echo "*************************************"
sh -c "$command"
echo "*************************************"
