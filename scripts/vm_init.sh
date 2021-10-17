# echo "Install git"
yum install -y git

echo "Install Java"
yum install -y java-1.8.0-openjdk

echo "Install ansible"
#yum install -y ansible
yum -y install epel-release
yum -y install ansible

ansible --version

echo "*************************************"
echo "VM successfully created!"
echo "*************************************"