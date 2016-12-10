sudo apt-get install --no-install-recommends flex bison build-essential csh
sudo mkdir -p /usr/class
sudo chown $USER /usr/class
cd /usr/class
wget http://spark-university.s3.amazonaws.com/stanford-compilers/vm/student-dist.tar.gz
tar -xf student-dist.tar.gz
ln -s /usr/class/cs143/cool ~/cool
new_path='PATH=/usr/class/cs143/cool/bin:$PATH'
if ! grep "$new_path" ~/.zshrc
then
	echo "$new_path" >> ~/.zshrc
fi
