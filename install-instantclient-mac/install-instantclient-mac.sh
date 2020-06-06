#!/bin/bash

shell=$1
instantClientDefaultVersion="19.3"
instantClientVersion=${2:-$instantClientDefaultVersion}
instantClientDirName="instantclient_${instantClientVersion//./_}"
allowedInstantClientVersions=("19.3" "18.1" "12.2")
instantClientBasicPackageName="instantclient-basic.$instantClientVersion.zip"
instantClientSdkPackageName="instantclient-sdk.$instantClientVersion.zip"
workDir=$PWD

if [ "$shell" != "bash" ] && [ "$shell" != "zsh" ]; then
  echo "[SHELL_ERROR]:💥 - You must pass as first param one of these 'bash' or 'zsh' shell. Default bash"
  exit 1;
fi

# Check if the given instant client version is allowed
if [[ ! " ${allowedInstantClientVersions[@]} " =~ " ${instantClientVersion} " ]]; then
  allowedVersions=$(IFS=,; echo "${allowedInstantClientVersions[*]}")
  echo "[INSTANT_CLIENT_VERSION]:💥 - Only these versions $allowedVersions are allowed. Default $instantClientDefaultVersion"
  exit 1
fi

printf "Moving to Home directory\n"
cd ~

# Set url according to the given instant client version
if [[ $instantClientVersion == "${allowedInstantClientVersions[0]}" ]]; then
  # 19.3.0.0
  instantclientBasicUrl=https://download.oracle.com/otn_software/mac/instantclient/193000/instantclient-basic-macos.x64-19.3.0.0.0dbru.zip
  instantClientSdkUrl=https://download.oracle.com/otn_software/mac/instantclient/193000/instantclient-sdk-macos.x64-19.3.0.0.0dbru.zip
  
  printf "⬇️  Downloading oracle Instant Client $instantClientVersion version - Basic package \n"
  curl -SL $instantclientBasicUrl -o $instantClientBasicPackageName || downloadError=true
  echo ""

  printf "⬇️  Downloading oracle Instant Client $instantClientVersion version - SDK package \n"
  curl -SL $instantClientSdkUrl -o $instantClientSdkPackageName || downloadError=true
  echo ""
  
  downloadError=false
  if [ $downloadError == true ]; then
    echo "[DOWNLOAD_ERROR]:💥 - We cannot download the required packages 😱"
    exit 1;
  fi

elif [[ $instantClientVersion == "${allowedInstantClientVersions[1]}" ]]; then
  # 18.1.0.0.0
  instantClientBasicPackageName="${workDir}/zip/instantclient-basic-macos.x64-18.1.0.0.0.zip"
  instantClientSdkPackageName="${workDir}/zip/instantclient-sdk-macos.x64-18.1.0.0.0-2.zip"
else
  # 12.2.0.1.0
  instantClientBasicPackageName="${workDir}/zip/instantclient-basic-macos.x64-12.2.0.1.0-2.zip"
  instantClientSdkPackageName="${workDir}/zip/instantclient-sdk-macos.x64-12.2.0.1.0-2.zip"
fi

# Extract zip files
unzipError=false
printf "Extracting the content of the $instantClientBasicPackageName package \n"
unzip $instantClientBasicPackageName || unzipError=true

printf "Extracting the content of the $instantClientSdkPackageName package \n"
unzip $instantClientSdkPackageName || unzipError=true

if [ $unzipError == true ]; then
  echo "[UNZIP_ERROR]:💥 - We cannot unzip the packages 😱"
  exit 1;
fi

DIR="lib"
if [ ! -d "$DIR" ]; then
  mkdir $DIR
  echo "Creating dir ${DIR}"
fi

# Create symbolic links
ln -s ~/$instantClientDirName/libclntsh.dylib ~/lib/

# Only for instant client 12
if [[ $instantClientVersion == "${allowedInstantClientVersions[2]}" ]]; then
  ln -s ~/instantclient_12_2/libclntsh.dylib.12.1 ~/lib/
fi

# Set file to put the environment vars according to the given bash
[[ $shell == "bash" ]] \
    && configFile=".bash_profile" \
    || configFile=".zshrc"

printf "Adding oracle environment vars on $configFile \n"
echo "" >> $configFile
echo "# oracle instantclient environment vars - $instantClientVersion" >> $configFile
echo "export OCI_LIB_DIR=~/$instantClientDirName" >> $configFile
echo "export OCI_INC_DIR=~/$instantClientDirName/sdk/include" >> $configFile
echo "export LD_LIBRARY_PATH=~/$instantClientDirName:$""LD_LIBRARY_PATH" >> $configFile

printf "Oracle instant client version $instantClientVersion installed successfully 🙌 \n"
echo "That's it 🎉"